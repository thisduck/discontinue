class Api::StreamResource < JSONAPI::Resource
  attributes :name, :state, :started_at, :finished_at, :humanized_time, :build_id

  belongs_to :build
  has_many :boxes
  has_many :test_results

  def state
    @model.aasm_state
  end
end
