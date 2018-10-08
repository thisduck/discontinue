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


  private
  def start_stream
    self.box_count.times do |index|
      box = self.boxes.create(
        box_number: index,
        instance_type: 'c4.xlarge',
        started_at: Time.now,
        finished_at: nil
      )

      Box.delay.start(box.id)
    end
  end


  def stop_stream
    self.boxes.each do |box|
      box.stop! if box.may_stop?
    end
  end
end
