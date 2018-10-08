class Api::BuildResource < JSONAPI::Resource
  attributes :branch, :sha, :build_request_id, :state,
    :hook_hash, :events, :repository_id, :created_at,
    :summary

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
end
