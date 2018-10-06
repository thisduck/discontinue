require 'string_file'
require 'runner'
require 'redis'
require 'humanize_seconds'

class Box < ApplicationRecord
  SPAWNLING_PREFIX = '-build-stream-box'
  BUILD_SCRIPT_PREFIX = "build_discontinue"

  belongs_to :stream
  before_destroy :destroy_machine!

  has_attached_file :output, path: ':rails_root/files/:class/:attachment/:id_partition/:style/:filename'
  validates_attachment_content_type :output, :content_type => ["text/plain"]

  include AASM
  aasm do 
    state :waiting, initial: true
    state :starting
    state :running
    state :stopped
    state :errored
    state :crashed
    state :passed
    state :failed

    event :pass_box, after: :clear_box do
      transitions to: :passed
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

    event :start, after_commit: :start_box do
      transitions from: :waiting, to: :starting
    end

    event :run, after_commit: :execute_build_script! do
      transitions from: :starting, to: :running
    end

    event :stop, after: :clear_box do
      transitions from: :running, to: :stopped
    end
  end

  def self.start(box_id)
    puts "going into spawnling for #{box_id}"
    Spawnling.new(:argv => "spawn #{SPAWNLING_PREFIX}-#{box_id}-") do
      begin
        puts "in spawnling for #{box_id}"
        box = Box.find box_id
        box.start!
      rescue => e
        message = "#{e.message}\n#{e.backtrace.join("\n")}"
        self.error_message = message
        self.error!
        puts message
        raise e
      end
    end
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
    return unless running?

    sync_log_file if machine.can_ssh?
    unless machine.build_running?
      update_status_from_output
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
    m.destroy
  end

  def build_box
    puts "build box for #{id}"

    [
      :setup_redis!,
      :setup_cache_yml!,
      :setup_scripts!,
      :setup_build_script!,
    ].each do |command|
      puts "Running #{command} on Box #{id}"
      write_to_log_file command.to_s.humanize
      send(command)
      puts "Done #{command} on Box #{id}"
    end
  end


  def start_box
    puts "start box for #{id}"
    self.update_attributes(
      started_at: Time.now,
      finished_at: nil,
      output: StringFile.create(body: 'hello', name: "output.txt"),
    )

    [
      :start_machine!,
      :wait_until_ssh!,
    ].each do |command|
      puts "Running #{command} on Box #{id}"
      write_to_log_file command.to_s.humanize
      send(command)
      puts "Done #{command} on Box #{id}"
    end

    run!
  end

  def write_to_log_file(message)
    File.open(output.path, "a") do |f|
      f.puts "DISCONTINUE[#{Time.now}] #{message}"
    end
  end

  def stop_box
    destroy_machine!
  end

  def machine
    @machine ||= Machine.new(instance_id)
  end

  def build
    stream.build
  end

  def execute_build_script!
    build_box

    puts "RUNNING BUILD SCRIPT ON BOX #{id}"
    self.reload

    sync_to_log_file

    runner = Runner.new
    # this should return immediately and run the script in the background on the remote machine.
    runner.run "ssh -n -f #{machine.at_login} 'export CREDIS_HOST=172.16.1.37:6379 S3_BUCKET=continue-cache AWS_ACCESS_KEY_ID=#{ENV['AWS_ACCESS_KEY_ID']} AWS_SECRET_ACCESS_KEY=#{ENV['AWS_SECRET_ACCESS_KEY']};  nohup bash --login ./#{BUILD_SCRIPT_PREFIX}_#{id}.sh >> log_continue_#{id}.log 2>&1 &'"

    unless runner.success?
      crash!
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
      - rvm use 2.3.7
      - gem install aws-sdk-s3 parallel mixlib-shellout

      - export TERM=xterm CI=1 CI_BUILD_NUMBER=#{build.id} CI_BUILD_STREAM_CONFIG=#{stream.build_stream_id} CI_STREAM_CONFIG=#{stream.build_stream_id.split('-').last} 
      - export CI_REPO_NAME='#{build.repository.name}' CI_REPO=#{build.repository.github_url} 
      - export CI_BRANCH=#{build.branch} CI_COMMIT_ID=#{build.sha} 
      - export CI_BOX_NUMBER=#{box_number} CI_BOX_COUNT=#{stream.box_count}
      - export CI_CPU_COUNT=`cat /proc/cpuinfo | grep '^processor' | wc -l` 
      - export CI_TOTAL_CPUS=`echo "\${CI_BOX_COUNT} * \${CI_CPU_COUNT}" | bc`

      - git clone --branch '#{build.branch}' --depth 20 #{build.repository.github_url} ~/clone
      - cd ~/clone
      - git checkout -qf #{build.sha}
      - ruby ~/scripts/continue_cache.rb fetch
      - cp ~/scripts/*.rb ~/clone/.
    COMMANDS

    post_commands = YAML.load <<~COMMANDS
      ---
      - echo '#{build_finished_text}'
      - rvm use 2.3.7
      - ruby ~/scripts/continue_cache.rb cache
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
  end

  def wait_until_ssh!
    puts "gonna ssh"
    until machine.can_ssh?
      puts "can't ssh [#{machine.ip_address}]"
      sleep 5
    end

    puts "did ssh [#{machine.ip_address}]"
  end

  def start_machine!
    puts "creating aws instance [#{self.stream.build.repository.name}][#{self.stream.name}]"
    instance = Machine.start
    puts "created aws instance [#{self.stream.build.repository.name}][#{self.stream.name}]"
    self.update_attributes(instance_id: instance.first.id)
  end

  def destroy_machine!
    machine.destroy if instance_id
  end

  class Machine
    attr_reader :instance_id

    def initialize(instance_id)
      @instance_id = instance_id
    end

    def instance
      @instance ||= Aws::EC2::Instance.new(
        instance_id,
        region: 'us-east-1',
      )
    end

    def ip_address
      @ip_address ||= instance.private_ip_address
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
        puts e.message
        false
      end
    end

    def build_running?
      return false unless can_ssh?

      runner = Runner.new
      runner.run "ssh -t #{at_login} 'ps aux | grep -v grep | grep #{Box::BUILD_SCRIPT_PREFIX}_'"

      runner.success?
    end

    def destroy
      instance.terminate
    end

    def self.start
      begin
        ec2 = Aws::EC2::Resource.new(
          region: 'us-east-1',
        )

        instance = ec2.create_instances({
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

          image_id: 'ami-0a3553817958f15f8',
          min_count: 1,
          max_count: 1,
          # key_name: 'MyGroovyKeyPair',
          security_group_ids: ['sg-0bbe8a0edf1c6ebbc'],
          # user_data: encoded_script,
          instance_type: 'c4.xlarge',
          # instance_type: 't3.2xlarge',
          subnet_id: 'subnet-9d1563d7',
        })


        # Wait for the instance to be created, running, and passed status checks
        ec2.client.wait_until(:instance_running, {instance_ids: [instance.first.id]})

        instance
      rescue => e
        puts "error with aws creation"
        puts e.message
        puts e.backtrace.join("\n")
        raise e
      end
    end
  end

  class UpdateBoxes
    def perform(number: 4)
      number.times do 
        Box.running.each do |box|
          begin
            box.update_sync_and_state
          rescue =>e 
            puts e.message
            puts e.backtrace.join("\n")
          end
        end
        sleep 3
      end
    end

  end
end
