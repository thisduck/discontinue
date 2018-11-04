class Api::BoxesController < ApiController
  # TODO: authenticate these requests
  skips = [:save_log_file, :update_log_file, :post_process, :cached, :acquire_populate_lock, :populate_queue, :wait_for_queue, :pop_queue]
  skip_before_action :verify_authenticity_token, only: skips
  skip_before_action :authenticate, only: skips

  def save_log_file
    box = Box.find params[:id]

    File.open(box.output.path, "w") do |f|
      f.write(params[:log])
    end

    box.update_column(:output_updated_at, Time.now)
  end

  def update_log_file
    box = Box.find params[:id]

    File.open(box.output.path, "a") do |f|
      f.write(params[:log])
    end

    box.update_column(:output_updated_at, Time.now)
  end

  def post_process
    box = Box.find params[:id]
    Box.delay.post_process(box.id)
  end

  def cached
    redis = Redis.new
    result = redis.del(params[:redis_key]).zero?

    render plain: result.to_s
  end

  def acquire_populate_lock
    redis = Redis.new
    result = !redis.del(params[:redis_key]).zero?

    render plain: result.to_s
  end

  def populate_queue
    redis = Redis.new
    redis_queue_key = params[:redis_queue_key]
    redis.del(redis_queue_key)
    params[:tests].each do |test|
      redis.rpush(redis_queue_key, test)
    end
    redis.set(params[:redis_ready_key], "ready")

    render plain: ''
  end

  def wait_for_queue
    redis = Redis.new
    result = redis.get(params[:redis_ready_key]).nil?

    render plain: result.to_s
  end

  def pop_queue
    redis = Redis.new
    redis_queue_key = params[:redis_queue_key]
    result = redis.lpop(redis_queue_key) || ""

    render plain: result
  end
end

