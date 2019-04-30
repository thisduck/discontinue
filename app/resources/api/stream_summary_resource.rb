class Api::StreamSummaryResource < JSONAPI::Resource
  attributes :results

  belongs_to :stream

  def results
    results = []
    counts = @model.test_results.group("test_type").group("status").count
    counts.each do |key, count|
      test_type, status = key
      results << {
        test_type: test_type,
        status: status,
        count: count
      }
    end

    results
  end
end
