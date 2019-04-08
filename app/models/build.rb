require 'humanize_seconds'
class Build < ApplicationRecord
  include BuildSearchData

  belongs_to :build_request
  belongs_to :repository

  has_many :streams, dependent: :destroy
  has_many :boxes, through: :streams
  has_many :test_results

  validates_presence_of :branch, :aasm_state, :build_request

  include AASM

  aasm do 
    state :waiting, initial: true
    state :running, after_enter: :start_build
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

    event :pass_build, after_commit: :after_pass_or_fail do
      transitions to: :passed
    end

    event :fail_build, after_commit: :after_pass_or_fail do
      transitions to: :failed
    end
  end

  def after_pass_or_fail
    notify(on: :finish)

    status = passed? ? "success" : "failure"

    repository.account.client.create_status(repository.integration_id.to_i, sha, status, {
      context: "Discontinue Test",
      target_url: url,
      description: "[#{humanized_time}] Tests #{aasm_state}.",
    })
  end

  def sync!
    self.reload
    if self.streams.all?(&:finished?)
      finished_at = Time.now
      duration = finished_at - started_at
      self.update_attributes(finished_at: finished_at, duration: duration)
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

  def environment_variables
    yaml_config['environment'] || {}
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

  def image_id
    yaml_config['image_id']
  end

  def instance_type
    yaml_config['instance_type']
  end

  def notification_options
    repository.yaml_config['notifications'] || []
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

  def time_taken
    (finished_at || Time.now) - started_at 
  end

  def humanized_time
    HumanizeSeconds.humanize(time_taken)
  end

  def url
    root_url = Rails.application.routes.url_helpers.url_for(
      controller: 'ember_cli/ember', 
      action: "index", 
      host: Rails.application.config.action_mailer.default_url_options[:host], 
      port: Rails.application.config.action_mailer.default_url_options[:port]
    )

    "#{root_url}builds/#{id}"
  end

  def notify(on:)
    # just for slack for now
    notification_options.each do |options|
      next if options['type'] != 'slack'
      next if options['branches'].none? {|filter| File.fnmatch(filter, branch) }

      channel = options['channel']

      send = false
      emojis = {
        "failed" => ":broken_heart:",
        "passed" => ":green_heart:",
      }
      extra = []
      if on == :start
        status = "Started"
        color = "warning"
        send = options['trigger'].include?('start')
      elsif on == :finish
        status =  "#{emojis[aasm_state]} #{aasm_state.humanize}"
        color = passed? ? "good" : "danger"

        if options['trigger'].include?('change')
          last_build = Build.where(branch: branch).where("finished_at is not null AND finished_at < ?", finished_at).order(finished_at: :desc).first

          if last_build
            if last_build.aasm_state != aasm_state
              send = true
              extra << {
                title: "Last Build",
                value: "<#{last_build.url}|##{last_build.id}> #{last_build.aasm_state.humanize}",
                short: false
              }
            end
          end
        end

        if passed? && options['trigger'].include?('pass')
          send = true
        elsif failed? && options['trigger'].include?('fail')
          send = true
        end
      end

      if send 
        pusher = hook_hash['pusher'] ? hook_hash['pusher']['name'] : '?'
        HTTParty.post(
          options['webhook'], 
          body: {
            channel: channel,
            username: "discontinue",
            color: color,
            fields: [
              {
                title: "Build",
                value: "<#{url}|##{id}>",
                short: true
              },
              {
                title: "Status",
                value: status,
                short: true
              },
              {
                title: "Repository",
                value: "<https://github.com/#{repository.name}|#{repository.name}>",
                short: true
              },
              {
                title: "Branch",
                value: "<https://github.com/#{repository.name}/tree/#{branch}|#{branch}>",
                short: true
              },
              {
                title: "Commit",
                value: "<#{hook_hash['compare']}|#{sha[0..9]}>",
                short: true
              },
              {
                title: "Pusher",
                value: "#{pusher}",
                short: true
              },
            ] + extra
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end
    end
  end

  # TODO: make these belong to stream
  # in proper manner
  def build_summary
    self
  end

  def build_timing
    self
  end

  def profile_summary
    self
  end

  private

  def start_build
    notify(on: :start)

    repository.account.client.create_status(repository.integration_id.to_i, sha, "pending", {
      context: "Discontinue Test",
      target_url: url,
      description: "Tests running.",
    })

    if self.stopped?
      self.streams.destroy_all
    end

    if self.repository.stream_configs.blank?
      self.fail_build!
      return
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
