class Stream < ApplicationRecord
  belongs_to :build
  has_many :boxes, dependent: :destroy

  include AASM
  aasm do 
    state :waiting, initial: true
    state :running, before_enter: :start_stream
    state :stopped, before_enter: :stop_stream
    state :errored

    event :start do
      transitions from: :waiting, to: :running
    end

    event :stop do
      transitions from: :running, to: :stopped
    end
  end

  def box_count
    1
  end

  private
  def start_stream
    self.box_count.times do |index|
      box = self.boxes.create(
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
