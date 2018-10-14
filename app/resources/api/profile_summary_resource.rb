class Api::ProfileSummaryResource < JSONAPI::Resource
  attributes :results

  belongs_to :build

  def results
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
