class Build < ApplicationRecord
  belongs_to :build_request
  belongs_to :repository

  validates_presence_of :branch, :sha, :aasm_state, :build_request

  include AASM

  aasm do 
    state :waiting, initial: true
    state :running, before_enter: :run_build
    state :stopped, before_enter: :stop_build

    event :run do
      transitions from: :waiting, to: :running
    end

    event :stop do
      transitions from: :running, to: :stopped
    end
  end

  def self.queue(options = {})
    options[:started_at] = Time.now
    options[:finished_at] = nil 
    options[:setup_commands] = options[:build_request].repository.setup_commands
    build = Build.create! options

    # Build.delay.start(build.id)

    build
  end

  private

  def run_build

  end

  def stop_build

  end
end
