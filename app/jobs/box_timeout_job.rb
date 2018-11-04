class BoxTimeoutJob < ApplicationJob
  queue_as :default

  ALLOWED_TIME_SINCE_UPDATE = 10.minutes

  def perform(box_id)
    box = Box.find box_id

    return unless box.active?

    last_updated = box.output_updated_at
    time_since_update = Time.now - last_updated

    if time_since_update >= ALLOWED_TIME_SINCE_UPDATE
      box.fail_box!

      File.open(box.output.path, "a") do |f|
        f.write("Output timed out.")
      end
    else
      BoxTimeoutJob.set(wait: ALLOWED_TIME_SINCE_UPDATE - time_since_update + 1.second).perform_later(box_id)
    end
  end
end
