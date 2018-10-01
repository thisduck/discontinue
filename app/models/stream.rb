class Stream < ApplicationRecord
  belongs_to :build
  has_many :boxes, dependent: :destroy

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

  private
  def start_stream
    self.box_count.to_i.times do |index|
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
