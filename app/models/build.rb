class Build < ApplicationRecord
  belongs_to :build_request
  belongs_to :repository

  has_many :streams, dependent: :destroy
  has_many :boxes, through: :streams
  has_many :test_results

  validates_presence_of :branch, :aasm_state, :build_request

  include AASM

  aasm do 
    state :waiting, initial: true
    state :running, before_enter: :start_build
    state :stopped, before_enter: :stop_build
    state :passed
    state :failed

    event :start do
      transitions from: :waiting, to: :running
    end

    event :restart do
      transitions from: :stopped, to: :running
    end

    event :stop do
      transitions from: :running, to: :stopped
    end

    event :pass_build do
      transitions to: :passed
    end

    event :fail_build do
      transitions to: :failed
    end
  end

  def sync!
    self.reload
    if self.streams.all?(&:finished?)
      self.update_attributes(finished_at: Time.now)
      if self.streams.collect(&:passed?).all?
        pass_build!
      else
        fail_build!
      end
    end
  end

  def self.queue(options = {})
    Build.transaction do
      options[:started_at] = Time.now
      options[:finished_at] = nil 
      options[:config] = options[:build_request].repository.config
      build = Build.create! options

      build.start!

      build
    end
  end

  def yaml_config
    YAML.load config
  end

  def setup_commands
    yaml_config['setup_commands']
  end

  def cache_dirs
    yaml_config['cache_dirs'] || []
  end

  def artifacts
    yaml_config['artifacts'] || []
  end

  def artifact_listing(keys: [])
    key = ([
      repository.name,
      "artifacts",
      "build_#{id}"
    ] + keys).join('/')

    s3 = Aws::S3::Resource.new(
      region: 'us-east-1'
    )
    s3_bucket = s3.bucket('continue-cache')
    s3_bucket.objects(prefix: key).to_a
  end

  private

  def start_build
    if self.stopped?
      self.streams.destroy_all
    end

    self.repository.stream_configs.each_with_index do |config, index|
      yaml = YAML.load config
      stream = self.streams.create!(
        started_at: Time.now,
        build_stream_id: "#{self.id}-#{index}",
        config: config,
        name: yaml['name']
      )

      puts "STREAM #{stream.build_stream_id} created!"

      Stream.delay.start(stream.id)
    end
  end

  def stop_build
    self.streams.each do |stream|
      stream.stop! if stream.may_stop?
    end
  end
end
