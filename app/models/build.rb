class Build < ApplicationRecord
  belongs_to :build_request
  belongs_to :repository

  has_many :streams, dependent: :destroy

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
      options[:setup_commands] = options[:build_request].repository.setup_commands
      build = Build.create! options

      build.start!

      build
    end
  end

  private

  def start_build
    if self.stopped?
      self.streams.destroy_all
    end

    self.repository.stream_configs.each_with_index do |config, index|
      stream = self.streams.create!(
        build_stream_id: "#{self.id}-#{index}",
        build_commands: config['build_commands'],
        name: config['name']
      )

      puts "STREAM #{stream.build_stream_id} created!"

      stream.start!
    end
  end

  def stop_build
    self.streams.each do |stream|
      stream.stop! if stream.may_stop?
    end
  end
end
