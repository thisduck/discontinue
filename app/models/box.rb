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
    box.write_to_log_file "[#{Time.now}] Starting connection"
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
      lines.last =~ /DISRESULT\[(.*)\]/
      return_code = $1
      lines.pop if return_code

      lines.first =~ /(.*?)\](.*)/
      time = $1

      if time.present?
        command = $2
        lines.shift

        {
          command: command,
          started_at: Time.parse(time),
          return_code: return_code,
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
        command[:finished_at] = active? ? nil : (finished_at || Time.now)
      end
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
    runner.rsync "#{output.path} #{machine.at_login}:log_continue_#{id}.log"
  end

  def sync_log_file
    runner = Runner.new
    runner.rsync "#{machine.at_login}:log_continue_#{id}.log #{output.path}"
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
    # runner.run %@ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -n -f #{machine.at_login} 'echo "fini" > ~/post_finished'@
    runner.ssh machine: machine.at_login, bash: false,
      options: '-o ConnectTimeout=4',
      command: %@echo "fini" > ~/post_finished@

    unless runner.success?
      crash!
    end

  end

  def public_env_vars
    {
      'TERM' => 'xterm',
      'CI' => '1',
      'CI_BUILD_ID' => build.id,
      'CI_STREAM_ID' => stream.id,
      'CI_BOX_ID' => id,
      'CI_BUILD_STREAM_CONFIG' => stream.build_stream_id,
      'CI_STREAM_CONFIG' => stream.build_stream_id.split('-').last,
      'CI_REPO_NAME' => build.repository.name,
      'CI_REPO' => build.repository.url,
      'CI_BRANCH' => build.branch,
      'CI_COMMIT_ID' => build.sha,
    }
  end

  # these shouldn't be env vars at some point.
  def private_env_vars
    {
      'DISCONTINUE_API' => "http://#{ENV['MACHINE_IP']}:8080",
      'AWS_REGION' => build.build_config.aws_region,
      'S3_BUCKET' => build.build_config.aws_cache_bucket,
      'AWS_ACCESS_KEY_ID' => build.build_config.aws_access_key,
      'AWS_SECRET_ACCESS_KEY' => build.build_config.aws_access_secret,
    }
  end

  def env_vars
    public_env_vars
      .merge(private_env_vars)
      .merge(stream.stream_config.environment_variables)
  end

  def env_exports
    environment_variables = env_vars.collect do |key, value|
      value = value.to_s.gsub('"', '\"')
      %/#{key}="#{value}"/
    end.join(' ')
    "export #{environment_variables};"
  end

  def store_cache!
    runner = Runner.new
    # should change this to not run as a long running backend task.
    runner.ssh machine: machine.at_login, environment: env_exports, 
      command: %^cd ~/clone; ~/scripts/discontinue_cache.sh cache >> ~/log_continue_#{id}.log 2>&1^

    unless runner.success?
      crash!
    end

  end

  def store_artifacts!
    runner = Runner.new
    runner.ssh machine: machine.at_login, environment: env_exports, 
      command: "cd ~/clone; ~/scripts/discontinue_artifact.sh >> ~/log_continue_#{id}.log 2>&1"

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
      stream.aws_options
    )
    s3_bucket = s3.bucket(build.build_config.aws_cache_bucket)
    s3_bucket.objects(prefix: key).to_a
  end

  def write_to_log_file(message, title: false)
    File.open(output.path, 'a') do |f|
      message = "DISCONTINUE[#{Time.now}] #{message}" if title
      f.puts message
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
    machine.set_tags(self)
    running = machine.running?
    can_ssh = running && machine.can_ssh?
    write_to_log_file "[#{Time.now}] Retrying connection: #{id} #{machine.ip_address}"
    write_to_log_file "[#{Time.now}] Machine running: #{machine.running?}"
    write_to_log_file "[#{Time.now}] Machine can ssh: #{can_ssh}"
    if can_ssh
      sync_to_log_file
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
    stream.sync!(resync: true)
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
        write_to_log_file command.to_s.humanize, title: true
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
        write_to_log_file command.to_s.humanize, title: true
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
    @machine ||= Machine.new(instance_id, aws_options: stream.aws_options)
  end

  def execute_build_script!

    puts "RUNNING BUILD SCRIPT ON BOX #{id}"
    self.reload

    sync_to_log_file

    runner = Runner.new

    runner.ssh machine: machine.at_login, command: "ssh -o StrictHostKeyChecking=no git@github.com"
    runner.ssh machine: machine.at_login, bash: false, command: "sudo yum install screen -y"

    unless runner.success?
      crash!
      return
    end

    # this should return immediately and run the script in the background on the remote machine.
    # and thus uses screen.
    runner.ssh machine: machine.at_login, environment: env_exports, bash: false,
      command: %^screen -dm bash -lc "bash ./#{BUILD_SCRIPT_PREFIX}_#{id}.sh >> log_continue_#{id}.log 2>&1"^

    unless runner.success?
      crash!
      return
    end

    runner.ssh machine: machine.at_login, environment: env_exports, bash: false,
      command: %^screen -dm bash -lc "~/scripts/discontinue_checker.sh >> checker.log 2>&1"^

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
    COMMANDS

    pre_commands = YAML.load <<~COMMANDS
      ---
      - export CI_BOX_NUMBER=#{box_number} CI_BOX_COUNT=#{stream.stream_config.box_count}
      - export CI_CPU_COUNT=`cat /proc/cpuinfo | grep '^processor' | wc -l` 
      - export CI_TOTAL_CPUS=`echo "\${CI_BOX_COUNT} * \${CI_CPU_COUNT}" | bc`

    COMMANDS

    pre_setup_commands = YAML.load <<~COMMANDS
      ---
      - export CI_BOX_RANGE=\${range::-1}
      - git clone --branch '#{build.branch}' --depth 20 #{build.repository.url} ~/clone
      - cd ~/clone
      - git checkout -qf #{build.sha}
      - ~/scripts/discontinue_cache.sh fetch
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
      f.puts %#exe() { echo "DISCONTINUE$(tstamp)\$ ${@/eval/}" ; "$@" ; rc=$?; echo "DISRESULT[$rc]"; if [[ $rc != 0  ]]; then exit $rc; fi }#

      f.puts "if ! mkdir /tmp/#{BUILD_SCRIPT_PREFIX}_#{id}.lock 2>/dev/null; then"
      f.puts '  echo "build is already running." >&2'
      f.puts '  exit 1'
      f.puts 'fi'

      commands = [
        {visible: true, commands: pre_commands},
        {visible: false, commands: invisible_pre_commands},
        {visible: true, commands: pre_setup_commands},
        {visible: true, commands: build.build_config.setup_commands || []},
        {visible: true, commands: stream.stream_config.build_commands || []},
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

    # write environment to tmp file.
    # the machine needs /etc/ssh/sshd_config
    # to have 
    # PermitUserEnvironment yes
    env_file = File.join(Rails.root, "tmp", "env_#{BUILD_SCRIPT_PREFIX}_#{id}.sh")
    File.open(env_file, "wb") do |f|
      environment_variables = env_vars.collect do |key, value|
        %/#{key}=#{value}/
      end.join("\n")
      f.puts environment_variables
    end

    # move ssh keys to ssh location
    runner = Runner.new
    runner.scp from: "~/.ssh/config ~/.ssh/id_rsa ~/.ssh/id_rsa.pub", to: "#{machine.at_login}:~/.ssh/."

    # move file to ssh location
    runner = Runner.new
    runner.scp from: build_file, to: "#{machine.at_login}:."
    runner.scp from: env_file, to: "#{machine.at_login}:.ssh/environment"

    File.unlink build_file
    File.unlink env_file
  end

  def setup_scripts!
    runner = Runner.new
    runner.scp options: "-r", from: "scripts", to: "#{machine.at_login}:."
    runner.ssh machine: machine.at_login,
      command: "cd ~/scripts; bundle install -j `cat /proc/cpuinfo | grep '^processor' | wc -l`"
  end

  def setup_artifacts_yml!
    artifacts = stream.stream_config.artifacts

    artifact_file = File.join(Rails.root, "tmp", "artifact_file_#{id}")
    File.open(artifact_file, "wb") do |f|
      f.write artifacts.to_yaml
    end

    runner = Runner.new
    runner.scp from: artifact_file, to: "#{machine.at_login}:~/artifacts.yml"

    File.unlink artifact_file
  end


  def setup_cache_yml!
    cache_dirs = stream.stream_config.cache_dirs

    cache_file = File.join(Rails.root, "tmp", "cache_file_#{id}")
    File.open(cache_file, "wb") do |f|
      f.write cache_dirs.to_yaml
    end

    runner = Runner.new
    runner.scp from: cache_file, to: "#{machine.at_login}:~/cache_file.yml"

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
    attr_reader :instance_id, :aws_options

    def initialize(instance_id, aws_options:)
      @instance_id = instance_id
      @aws_options = aws_options
    end

    def instance
      @instance ||= Aws::EC2::Instance.new(
        instance_id,
        aws_options
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
        runner.ssh machine: at_login, bash: false, options: "-o ConnectTimeout=4", command: "ls"

        runner.success?
      rescue => e
        puts "CANNOT SSH: #{e.message}"
        false
      end
    end

    def post_process_finished?
      return true unless can_ssh?

      runner = Runner.new
      runner.ssh machine: machine.at_login, bash: false, options: "-o ConnectTimeout=4", command: "cat ~/post_finished"

      runner.success?
    end

    def build_running?
      return false unless can_ssh?

      runner = Runner.new
      runner.ssh machine: machine.at_login, bash: false, options: "-o ConnectTimeout=4", command: "ps aux | grep -v grep | grep #{Box::BUILD_SCRIPT_PREFIX}_"

      runner.success?
    end

    def destroy
      # sir = instance.spot_instance_request_id
      # if this is a spot instance we should cancel the spot request
      instance.terminate
    rescue Aws::EC2::Errors::InvalidInstanceIDNotFound
      puts "Machine Destroy: Instance ID not found. [#{instance_id}]"
    end

    def set_tags(box)
      instance.create_tags({ tags: [
        { key: 'Name', value: "Discontinue Box #{box.id}" },
        { key: 'Group', value: "Discontinue Build #{box.build.id}, Stream #{box.stream.id} #{box.stream.name}" },
        { key: 'Discontinue', value: "true" }
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
