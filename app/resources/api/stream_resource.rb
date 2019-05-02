class Api::StreamResource < JSONAPI::Resource
  attributes :name, :state, :started_at, :finished_at, :humanized_time, :build_id

  belongs_to :build, always_include_linkage_data: true
  has_many :boxes
  has_many :test_results
  has_one :stream_summary

  def state
    @model.aasm_state
  end
end
