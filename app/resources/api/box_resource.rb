class Api::BoxResource < JSONAPI::Resource
  attributes :state, :started_at, :finished_at, :stream_id, :humanized_time,
    :box_number

  belongs_to :stream
  has_many :commands
  has_many :artifacts

  def state
    @model.aasm_state
  end
end
