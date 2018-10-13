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

    event :stop do
      transitions from: :running, to: :stopped
    end
  end

  def after_pass
    build.sync!
  end

  def after_fail
    build.sync!
  end

  def finished?
    finished_at.present?
  end

  def sync!
    self.reload
    if self.boxes.all?(&:finished?)
      self.update_attributes(finished_at: Time.now)
      if self.boxes.collect(&:passed?).all?
        pass_stream!
      else
        fail_stream!
      end
    end
  end

  def yaml_config
    YAML.load config
  end

  def build_commands
    yaml_config['build_commands']
  end

  def environment_variables
    build.environment_variables.merge(
      yaml_config['environment'] || {}
    )
  end

  def box_count
    yaml_config['box_count'].to_i
  end

  def cache_dirs
    build.cache_dirs +
      ( yaml_config['cache_dirs'] || [])
  end

  def artifacts
    build.artifacts +
      ( yaml_config['artifacts'] || [])
  end

  def image_id
    ( yaml_config['image_id'] || build.image_id)
  end

  def instance_type
    ( yaml_config['instance_type'] || build.instance_type)
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

  private
  def start_stream
    self.box_count.times do |index|
      box = self.boxes.create(
        box_number: index,
        instance_type: 'c4.xlarge',
        started_at: Time.now,
        finished_at: nil,
        output: StringFile.create(body: 'hello', name: "output.txt"),
      )

      box.write_to_log_file("Creating Machine Instance")

    end

    instances = create_instances
    boxes.each_with_index do |box, index|
      instance = instances[index]
      box.update_attributes(instance_id: instance.id)
      Box.delay.start(box.id)
    end
  end

  def create_instances
    begin
      ec2 = Aws::EC2::Resource.new(
        region: 'us-east-1',
      )

      puts "Creating instances for stream [#{id}]"

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

        image_id: image_id,
        min_count: box_count,
        max_count: box_count,
        security_group_ids: ['sg-0bbe8a0edf1c6ebbc'],
        instance_type: instance_type,
        # instance_type: 't3.2xlarge',
        subnet_id: 'subnet-9d1563d7',
      })

      puts "Created instances for stream [#{id}]"



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
