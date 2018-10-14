require 'humanize_seconds'
class Api::BuildResource < JSONAPI::Resource
  attributes :branch, :sha, :build_request_id, :state,
    :hook_hash, :events, :repository_id, :created_at,
    :summary, :timings, :profile_summary

  belongs_to :build_request
  belongs_to :repository

  has_many :streams

  paginator :paged
  filter :branch, apply: ->(records, value, _options) {
    records.where("branch like ?", "%#{value[0]}%")
  }

  def state
    @model.aasm_state
  end

  def events
    @model.aasm.events(permitted: true).map(&:name)
  end

  def timings
    results = []
    times = []
    @model.streams.each do |stream|
      box_times = stream.boxes.collect(&:time_taken).sum
      times << box_times

      results << {
        name: stream.name,
        time: stream.humanized_time,
        total_time: HumanizeSeconds.humanize(box_times)
      }
    end

    results << {
      name: "Total",
      time: @model.humanized_time,
      total_time: HumanizeSeconds.humanize(times.sum)
    }
    results
  end

  def summary
    results = []
    counts = @model.test_results.group("stream_id").group("test_type").group("status").count
    counts.each do |key, count|
      stream_id, test_type, status = key
      results << {
        stream_id: stream_id,
        test_type: test_type,
        status: status,
        count: count
      }
    end

    results
  end


  def profile_summary
    results = []

    @model.streams.each do |stream|
      slow_tests = stream.test_results.select("file_path, line_number, SUM(duration) as total_duration").group(:file_path, :line_number).order("total_duration desc").limit(10).collect{|x| profile_result(x)}
      slow_files = stream.test_results.select("file_path, SUM(duration) as total_duration").group(:file_path).order("total_duration desc").limit(10).collect{|x| profile_result(x)}
      results << {
        stream_name: stream.name,
        slow_tests: slow_tests.as_json,
        slow_files: slow_files.as_json,
      }
    end

    results
  end

  private

  def profile_result(result)
    name = result.file_path
    if result.try(:line_number)
      name = "#{name}:#{result.line_number}"
    end

    {
      name: name,
      duration: HumanizeSeconds.humanize(result.total_duration / 1_000_000_000)
    }
  end
end
