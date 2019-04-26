class BoxTimeoutJob < ApplicationJob
  queue_as :default

  ALLOWED_TIME_SINCE_UPDATE = 10.minutes

  def perform(box_id)
    box = Box.find box_id

    return unless box.active?

    last_updated = box.output_updated_at
    time_since_update = Time.now - last_updated
    allowed_time_since_update = box.build.build_config.box_timeout&.to_f&.minutes || ALLOWED_TIME_SINCE_UPDATE

    if time_since_update >= allowed_time_since_update
      box.fail_box!

      File.open(box.output.path, "a") do |f|
        f.puts("")
        f.puts("Output timed out.")
      end
    else
      BoxTimeoutJob.set(wait: ALLOWED_TIME_SINCE_UPDATE - time_since_update + 1.second).perform_later(box_id)
    end
  end
end
