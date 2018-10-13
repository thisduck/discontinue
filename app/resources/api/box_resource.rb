class Api::BoxResource < JSONAPI::Resource
  attributes :state, :started_at, :finished_at, :stream_id, :humanized_time

  belongs_to :stream
  has_many :commands

  def state
    @model.aasm_state
  end
end
