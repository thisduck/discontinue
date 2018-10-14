class Api::BuildSummaryResource < JSONAPI::Resource
  attributes :results

  belongs_to :build

  def results
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
end
