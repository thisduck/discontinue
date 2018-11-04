require 'string_file'
require 'runner'
require 'redis'
require 'humanize_seconds'
require 'digest'

class Box < ApplicationRecord
  SPAWNLING_PREFIX = '-build-stream-box'
  BUILD_SCRIPT_PREFIX = "build_discontinue"

  belongs_to :stream
  has_one :build, through: :stream
  before_destroy :destroy_machine!

  has_many :test_results

  has_attached_file :output, path: ':rails_root/files/:class/:attachment/:id_partition/:style/:filename'
  validates_attachment_content_type :output, :content_type => ["text/plain"]

  include AASM
  aasm do 
    state :waiting, initial: true
    state :connecting
    state :running
    state :post_processing

    state :stopped
    state :errored
    state :crashed
    state :passed
    state :failed

    event :pass_box, after: :clear_box do
      transitions to: :passed
    end

    event :post_process, after_commit: :post_process_box do
      transitions from: :running, to: :post_processing
    end

    event :fail_box, after: :clear_box do
      transitions to: :failed
    end

    event :crash, after: :clear_box do
      transitions to: :crashed
    end

    event :error, after: :clear_box do
      transitions to: :errored
    end

    event :connect, after_commit: :connect_box do
      transitions from: :waiting, to: :connecting
    end

    event :run, after_commit: :run_box do
      transitions from: :connecting, to: :running
    end

    event :stop, after: :clear_box do
      transitions to: :stopped
    end
  end

  def self.post_process(box_id)
    box = Box.find box_id
    box.post_process!
  end

  def self.connect(box_id)
    box = Box.find box_id
    box.connect!
  end

  def output_content_without_encoding
    Paperclip.io_adapters.for(output).read
  end

  def output_content
    return '' if output_content_without_encoding.blank?
    output_content_without_encoding
      .encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
      .force_encoding("utf-8")
  end

  def active?
    aasm_state.end_with?("ing")
  end

  def output_content_split
    return [] if output_content.blank?

    commands = output_content.split("DISCONTINUE[").map do |split|
      lines = split.split("\n")
      lines.first =~ /(.*?)\](.*)/
      time = $1

      if time.present?
        command = $2
        lines.shift

        {
          command: command,
          started_at: Time.parse(time),
          lines: lines.join("\n")
        }
      end
    end.compact

    commands.each_with_index do |command, index|
      command[:id] = "#{stream.build.id}-#{stream.id}-#{id}-#{index}"
      state = "passed"
      if command == commands.last
        state = active? ? "active" : aasm_state
      end
      command[:state] = state
      if commands[index + 1].present?
        command[:finished_at] = commands[index + 1][:started_at]
      else
        command[:finished_at] = (finished_at || Time.now)
      end
      command[:humanized_time] = HumanizeSeconds.humanize(command[:finished_at] - command[:started_at])
    end

    commands
  end

  def update_sync_and_state
    self.reload
    return unless running?

    sync_log_file if machine.can_ssh?
    unless machine.build_running?
      puts "build not running time for post [#{id}]"
      post_process!
    end
  end

  def sync_to_log_file
    runner = Runner.new
    runner.run "rsync #{output.path} #{machine.at_login}:log_continue_#{id}.log"
  end

  def sync_log_file
    runner = Runner.new
    runner.run "rsync #{machine.at_login}:log_continue_#{id}.log #{output.path}"
  end

  def finished?
    finished_at.present?
  end

  def commands
    Command::Relation.new(self)
  end

  def artifacts
    Artifact::Relation.new(self)
  end

  def finish_post_processing!
    sync_log_file if machine.can_ssh?
    runner = Runner.new
    runner.run %@ssh -n -f #{machine.at_login} 'echo "fini" > ~/post_finished'@

    unless runner.success?
      crash!
    end

  end

  def env_exports
    environment_variables = stream.environment_variables.collect do |key, value|
      %/#{key}="#{value.gsub('"', '\"')}"/
    end.join(' ')
    [
      "export TERM=xterm CI=1 CI_BUILD_ID=#{build.id} CI_STREAM_ID=#{stream.id} CI_BOX_ID=#{id} CI_BUILD_STREAM_CONFIG=#{stream.build_stream_id} CI_STREAM_CONFIG=#{stream.build_stream_id.split('-').last}" ,
      "export CI_REPO_NAME='#{build.repository.name}' CI_REPO=#{build.repository.url}" ,
      "export CI_BRANCH=#{build.branch} CI_COMMIT_ID=#{build.sha}" ,
      "export DISCONTINUE_API='http://54.242.5.53:8080'" ,
      ( "export #{environment_variables}" if environment_variables.present? ) ,
    ].compact
  end

  def store_cache!
    runner = Runner.new
    runner.run %@ssh -n -f #{machine.at_login} '#{env_exports.join("; ")}; export S3_BUCKET=continue-cache AWS_ACCESS_KEY_ID=#{ENV['AWS_ACCESS_KEY_ID']} AWS_SECRET_ACCESS_KEY=#{ENV['AWS_SECRET_ACCESS_KEY']};  bash -lc "cd ~/clone; ruby ~/scripts/continue_cache.rb cache >> ~/log_continue_#{id}.log 2>&1" '@

    unless runner.success?
      crash!
    end

  end

  def store_artifacts!
    runner = Runner.new
    # this should return immediately and run the script in the background on the remote machine.
    runner.run %@ssh -n -f #{machine.at_login} '#{env_exports.join("; ")}; export S3_BUCKET=continue-cache AWS_ACCESS_KEY_ID=#{ENV['AWS_ACCESS_KEY_ID']} AWS_SECRET_ACCESS_KEY=#{ENV['AWS_SECRET_ACCESS_KEY']};  bash -lc "cd ~/clone; ruby ~/scripts/artifact.rb >> ~/log_continue_#{id}.log 2>&1" '@

    unless runner.success?
      crash!
    end

  end

  def update_post_and_state
    return unless post_processing?

    sync_log_file if machine.can_ssh?
    if machine.post_process_finished?
      update_status_from_output
    end
  end

  def process_report_data!
    results = report_data.map do |test|
      test['test_id'] = Digest::SHA256.hexdigest test['test_id']
      test['build_id'] = build.id
      test['stream_id'] = stream.id
      test['box_id'] = id
      TestResult.new(test.symbolize_keys)
    end

    TestResult.import results
  end

  def report_data
    objects = artifact_listing.select{|x| x.key.to_s.include?('tmp/report') }
    data = []
    objects.each do |object|
      data = data + JSON.parse(object.get.body.read)
    end

    data
  end

  def artifact_listing(keys: [])
    key = ([
      build.repository.name,
      "artifacts",
      "build_#{build.id}",
      "stream_#{stream.id}",
      "box_#{id}",
    ] + keys).join('/')

    s3 = Aws::S3::Resource.new(
      region: 'us-east-1'
    )
    s3_bucket = s3.bucket('continue-cache')
    s3_bucket.objects(prefix: key).to_a
  end

  def write_to_log_file(message)
    File.open(output.path, "a") do |f|
      f.puts "DISCONTINUE[#{Time.now}] #{message}"
    end
  end

  def time_taken
    (finished_at || Time.now) - started_at 
  end

  def humanized_time
    HumanizeSeconds.humanize(time_taken)
  end

  def self.retry_connection(box_id)
    box = Box.find box_id
    box.retry_connection
  end

  def retry_connection
    if machine.running? && machine.can_ssh?
      sync_to_log_file
      machine.set_tags(self)
      run!
      return
    end

    Box.delay(run_at: 5.seconds.from_now).retry_connection(id)
  end

  private

  def update_status_from_output
    runner = Runner.new
    runner.run "cat #{output.path} | grep '#{build_finished_text}'"

    if runner.success?
      pass_box!
    else
      fail_box!
    end
  end

  def clear_box
    m = machine if instance_id
    self.update_attributes(finished_at: Time.now, instance_id: nil)
    stream.sync!
  ensure
    m&.destroy
  end

  def post_process_box
    begin
      puts "post process box for #{id}"

      [
        :store_cache!,
        :store_artifacts!,
        :finish_post_processing!,
        :process_report_data!,
        :update_status_from_output,
      ].each do |command|
        puts "Running #{command} on Box #{id}"
        sync_log_file
        write_to_log_file command.to_s.humanize
        sync_to_log_file
        send(command)
        puts "Done #{command} on Box #{id}"
      end
    rescue => e
      puts "error in post_process_box"
      puts e.message
      puts e.backtrace.join("\n")
      raise e
    end
  end

  def connect_box
    Box.delay.retry_connection(id)
  end

  def run_box
    begin
      puts "run box for #{id}"

      [
        :setup_redis!,
        :setup_cache_yml!,
        :setup_artifacts_yml!,
        :setup_scripts!,
        :setup_build_script!,
      ].each do |command|
        puts "Running #{command} on Box #{id}"
        write_to_log_file command.to_s.humanize
        send(command)
        puts "Done #{command} on Box #{id}"
      end

      execute_build_script!
    rescue => e
      puts "error in run_box"
      puts e.message
      puts e.backtrace.join("\n")
      raise e
    end
  end

  def stop_box
    destroy_machine!
  end

  def machine
    @machine ||= Machine.new(instance_id)
  end

  def execute_build_script!

    puts "RUNNING BUILD SCRIPT ON BOX #{id}"
    self.reload

    sync_to_log_file

    runner = Runner.new
    runner.run %@ssh -n -f #{machine.at_login} 'bash --login -c "gem install aws-sdk-s3 parallel mixlib-shellout redis rufus-scheduler httparty faraday &> output.txt"'@

    unless runner.success?
      crash!
      return
    end

    # this should return immediately and run the script in the background on the remote machine.
    runner.run "ssh -n -f #{machine.at_login} '#{env_exports.join("; ")}; export S3_BUCKET=continue-cache AWS_ACCESS_KEY_ID=#{ENV['AWS_ACCESS_KEY_ID']} AWS_SECRET_ACCESS_KEY=#{ENV['AWS_SECRET_ACCESS_KEY']};  nohup bash --login ./#{BUILD_SCRIPT_PREFIX}_#{id}.sh >> log_continue_#{id}.log 2>&1 &'"

    unless runner.success?
      crash!
      return
    end

    runner.run %@ssh -n -f #{machine.at_login} "nohup bash --login -c '#{env_exports.join("; ")}; export S3_BUCKET=continue-cache AWS_ACCESS_KEY_ID=#{ENV['AWS_ACCESS_KEY_ID']} AWS_SECRET_ACCESS_KEY=#{ENV['AWS_SECRET_ACCESS_KEY']};    ruby ~/scripts/discontinue_checker.rb' >> checker.log 2>&1 &"@

    unless runner.success?
      crash!
      return
    end
  end

  def build_finished_text
    'DISCONTINUE BUILD FINISHED.'
  end

  def setup_build_script!
    invisible_pre_commands = YAML.load <<~COMMANDS
      ---
      - start_number=`echo "(\${CI_BOX_NUMBER} * \${CI_CPU_COUNT}) + 1" | bc`
      - end_number=`echo "(\${CI_BOX_NUMBER} + 1) * \${CI_CPU_COUNT} + 1" | bc`
      - range=''
      - while [ \\$start_number -lt \\$end_number ]; do range+="\\${start_number},"; let start_number=start_number+1; done
      - export CI_BOX_RANGE=\${range::-1}
    COMMANDS

    pre_commands = YAML.load <<~COMMANDS
      ---
      - export CI_BOX_NUMBER=#{box_number} CI_BOX_COUNT=#{stream.box_count}
      - export CI_CPU_COUNT=`cat /proc/cpuinfo | grep '^processor' | wc -l` 
      - export CI_TOTAL_CPUS=`echo "\${CI_BOX_COUNT} * \${CI_CPU_COUNT}" | bc`

      - git clone --branch '#{build.branch}' --depth 20 #{build.repository.url} ~/clone
      - cd ~/clone
      - git checkout -qf #{build.sha}
      - ruby ~/scripts/continue_cache.rb fetch
      - cp ~/scripts/*.rb ~/clone/.
    COMMANDS

    post_commands = YAML.load <<~COMMANDS
      ---
      - echo '#{build_finished_text}'
    COMMANDS

    # write build command to tmp file.
    build_file = File.join(Rails.root, "tmp", "#{BUILD_SCRIPT_PREFIX}_#{id}.sh")
    File.open(build_file, "wb") do |f|
      f.puts "#!/bin/bash -l"
      f.puts "source ~/.bashrc"
      f.puts 'tstamp() { date "+[%Y-%m-%d %T %z]"; }'
      # f.puts %/exe() { echo "CONTINUE$(tstamp)\$ $@" ; "$@" ; }/
      f.puts %#exe() { echo "DISCONTINUE$(tstamp)\$ ${@/eval/}" ; "$@" ; rc=$?; if [[ $rc != 0  ]]; then exit $rc; fi }#

      f.puts "if ! mkdir /tmp/#{BUILD_SCRIPT_PREFIX}_#{id}.lock 2>/dev/null; then"
      f.puts '  echo "build is already running." >&2'
      f.puts '  exit 1'
      f.puts 'fi'

      commands = [
        {visible: true, commands: pre_commands},
        {visible: false, commands: invisible_pre_commands},
        {visible: true, commands: build.setup_commands},
        {visible: true, commands: stream.build_commands},
        {visible: true, commands: post_commands},
      ].flatten

      commands.each do |group|
        group[:commands].each do |line|
          line = line.encode(universal_newline: true)
          if group[:visible]
            f.puts %/exe eval "#{line.gsub('"', '\"')}"/
          else
            f.puts %/eval "#{line.gsub('"', '\"')}"/
          end
        end
      end
    end

    # move ssh keys to ssh location
    runner = Runner.new
    runner.run "scp ~/.ssh/config ~/.ssh/id_rsa ~/.ssh/id_rsa.pub #{machine.at_login}:~/.ssh/. "

    # move file to ssh location
    runner = Runner.new
    runner.run "scp #{build_file} #{machine.at_login}:. "

    File.unlink build_file
  end

  def setup_scripts!
    runner = Runner.new
    runner.run "scp -r scripts #{machine.at_login}:."
  end

  def setup_artifacts_yml!
    artifacts = stream.artifacts

    artifact_file = File.join(Rails.root, "tmp", "artifact_file_#{id}")
    File.open(artifact_file, "wb") do |f|
      f.write artifacts.to_yaml
    end

    runner = Runner.new
    runner.run "scp #{artifact_file} #{machine.at_login}:~/artifacts.yml"

    File.unlink artifact_file
  end


  def setup_cache_yml!
    cache_dirs = stream.cache_dirs

    cache_file = File.join(Rails.root, "tmp", "cache_file_#{id}")
    File.open(cache_file, "wb") do |f|
      f.write cache_dirs.to_yaml
    end

    runner = Runner.new
    runner.run "scp #{cache_file} #{machine.at_login}:~/cache_file.yml"

    File.unlink cache_file
  end

  def setup_redis!
    redis = Redis.new
    redis.set("discontinue_#{stream.build_stream_id}", stream.build.id)
    redis.set("discontinue_#{stream.build_stream_id}_cache", stream.build.id)
  end

  def destroy_machine!
    machine.destroy if instance_id
  end

  class Machine
    attr_reader :instance_id

    def initialize(instance_id)
      @instance_id = instance_id
    end

    def ec2
      Aws::EC2::Resource.new( region: 'us-east-1',)
    end

    def instance
      @instance ||= Aws::EC2::Instance.new(
        instance_id,
        region: 'us-east-1',
      )
    end

    def running?
      instance.state.name == "running"
    end

    def ip_address
      # @ip_address ||= instance.private_ip_address
      @ip_address ||= instance.public_ip_address
    end

    def at_login
      "admin@#{ip_address}"
    end

    def can_ssh?
      return false if ip_address.blank?
      begin
        runner = Runner.new
        runner.run "ssh #{at_login} 'ls' "

        runner.success?
      rescue => e
        puts "CANNOT SSH: #{e.message}"
        false
      end
    end

    def post_process_finished?
      return true unless can_ssh?

      runner = Runner.new
      runner.run "ssh -t #{at_login} 'cat ~/post_finished'"

      runner.success?
    end

    def build_running?
      return false unless can_ssh?

      runner = Runner.new
      runner.run "ssh -t #{at_login} 'ps aux | grep -v grep | grep #{Box::BUILD_SCRIPT_PREFIX}_'"

      runner.success?
    end

    def destroy
      instance.terminate
    rescue Aws::EC2::Errors::InvalidInstanceIDNotFound
      puts "Machine Destroy: Instance ID not found. [#{instance_id}]"
    end

    def set_tags(box)
      instance.create_tags({ tags: [
        { key: 'Name', value: "Discontinue Box #{box.id}" },
        { key: 'Group', value: "Discontinue Build #{box.build.id}, Stream #{box.stream.id} #{box.stream.name}" }
      ]})
    end
  end

  class UpdateBoxes
    def perform(number: 4)
      number.times do 
        Box.running.each do |box|
          begin
            box.update_sync_and_state
          rescue => e 
            puts e.message
            puts e.backtrace.join("\n")
          end
        end
      end
    end

  end
end
