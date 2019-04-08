require 'humanize_seconds'
class Stream < ApplicationRecord
  belongs_to :build
  has_many :boxes, dependent: :destroy
  has_many :test_results

  include AASM
  aasm do 
    state :waiting, initial: true
    state :running
    state :stopped, before_enter: :stop_stream
    state :errored
    state :passed
    state :failed

    event :start, after_commit: :start_stream do
      transitions from: :waiting, to: :running
    end

    event :pass_stream, after: :after_pass do
      transitions to: :passed
    end

    event :fail_stream, after: :after_fail do
      transitions to: :failed
    end

    event :stop, after: :after_stop do
      transitions from: :running, to: :stopped
    end
  end

  def after_stop
    finish!
    build.sync!
  end

  def after_pass
    finish!
    build.sync!
  end

  def after_fail
    finish!
    build.sync!
  end

  def finished?
    finished_at.present?
  end

  def finish!
    finished_at = Time.now
    duration = finished_at - started_at
    self.update_attributes(finished_at: finished_at, duration: duration)
  end

  def sync!
    self.reload
    if self.boxes.all?(&:finished?)
      if self.boxes.collect(&:passed?).all?
        pass_stream!
      else
        fail_stream!
      end
    end
  end

  def stream_config
    @stream_config ||= StreamConfig.new config: config, build_config: build.build_config
  end

  def artifact_listing(keys: [])
    key = ([
      build.repository.name,
      "artifacts",
      "build_#{build.id}",
      "stream_#{id}"
    ] + keys).join('/')

    s3 = Aws::S3::Resource.new(
      region: 'us-east-1'
    )
    s3_bucket = s3.bucket('continue-cache')
    s3_bucket.objects(prefix: key).to_a
  end

  def self.start(stream_id)
    stream = Stream.find stream_id
    stream.start!
  end

  def time_taken
    (finished_at || Time.now) - started_at 
  end

  def humanized_time
    HumanizeSeconds.humanize(time_taken)
  end

  private
  def start_stream
    begin
      box_count = stream_config.box_count
      if box_count.blank? || box_count.zero?
        self.fail_stream!
        return
      end

      box_count.times do |index|
        box = self.boxes.create(
          box_number: index,
          instance_type: stream_config.instance_type,
          started_at: Time.now,
          finished_at: nil,
          output: StringFile.create(body: 'hello', name: "output.txt"),
        )

        box.write_to_log_file("Creating Machine Instance")
      end

      Rails.logger.info "Stream #{self.id}: Creating AWS instances"
      instances = create_instances
      Rails.logger.info "Stream #{self.id}: Created AWS instances"
      boxes.each_with_index do |box, index|
        instance = instances[index]
        Rails.logger.info "Stream #{self.id}: Updating Box #{box.id} with Instance #{instance.id}"
        box.update_attributes(instance_id: instance.id)
        Box.delay.connect(box.id)
        BoxTimeoutJob.perform_later(box.id)
      end
    rescue => e
      puts "error in run_box"
      puts e.message
      puts e.backtrace.join("\n")
      raise e
    end
  end

  def create_instances
    begin
      ec2 = Aws::EC2::Resource.new(
        region: 'us-east-1',
      )

      Rails.logger.info "Creating instances for stream [#{id}]"

      instances = ec2.create_instances({
        block_device_mappings: [
          {
            device_name: "/dev/sda1",
            ebs: {
              delete_on_termination: true,
              volume_size: 30,
              volume_type: "gp2",
            },
          },
        ],
        instance_market_options: {
          market_type: "spot", # accepts spot
        },

        image_id: stream_config.image_id,
        min_count: stream_config.box_count,
        max_count: stream_config.box_count,
        security_group_ids: ['sg-0bbe8a0edf1c6ebbc'],
        instance_type: stream_config.instance_type,
        subnet_id: 'subnet-9d1563d7',
      })

      Rails.logger.info "Created instances for stream [#{id}]"

      instances
    rescue => e
      puts "error with aws creation"
      puts e.message
      puts e.backtrace.join("\n")
      raise e
    end

  end


  def stop_stream
    self.boxes.each do |box|
      box.stop! if box.may_stop?
    end
  end
end
