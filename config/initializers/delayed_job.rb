module CustomFailedJob
  def handle_failed_job(job, error)
    super
    ExceptionNotifier.notify_exception(error, data: {job: job}) if Rails.env.production?
  end
end

class Delayed::Worker
  prepend CustomFailedJob
end
