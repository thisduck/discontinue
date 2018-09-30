require 'string_file'

class Box < ApplicationRecord
  belongs_to :stream
  before_destroy :destroy_machine!

  has_attached_file :output, path: ':rails_root/files/:class/:attachment/:id_partition/:style/:filename'
  validates_attachment_content_type :output, :content_type => ["text/plain"]

  include AASM
  aasm do 
    state :waiting, initial: true
    state :running, before_enter: :start_box
    state :stopped, before_enter: :stop_box
    state :errored, before_enter: :stop_box

    event :error do
      transitions to: :errored
    end

    event :start do
      transitions from: :waiting, to: :running
    end

    event :stop do
      transitions from: :running, to: :stopped
    end
  end

  def self.start(box_id)
    box = Box.find box_id
    box.start!
  end

  private

  def spawnling_prefix
    '-build-stream-box'
  end

  def start_box
    Spawnling.new(:argv => "spawn #{spawnling_prefix}-#{self.id}-") do
      begin
        self.update_attributes(
          started_at: Time.now,
          finished_at: nil,
          output: StringFile.create(body: 'hello there.', name: "output.txt"),
        )

        start_machine!
      rescue => e
        message = "#{e.message}\n#{e.backtrace.join("\n")}"
        self.error_message = message
        self.error!
        puts message
        raise e
      end
    end

  end

  def stop_box
    destroy_machine!
  end

  def machine
    @machine ||= Machine.new(instance_id)
  end

  def start_machine!
    puts "creating aws instance [#{self.stream.build.repository.name}][#{self.stream.name}]"
    instance = Machine.start
    puts "created aws instance [#{self.stream.build.repository.name}][#{self.stream.name}]"
    self.instance_id = instance.first.id
    self.save!
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
      runner = Runner.new
      runner.run "ssh -t #{at_login} 'ps aux | grep -v grep | grep build_continue_'"

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
end
