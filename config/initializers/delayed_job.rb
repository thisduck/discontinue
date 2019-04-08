module CustomFailedJob
  def handle_failed_job(job, error)
    super
    ExceptionNotifier.notify_exception(error, data: {job: job})
  end
end

class Delayed::Worker
  prepend CustomFailedJob
end
