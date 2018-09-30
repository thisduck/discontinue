class Api::BoxResource < JSONAPI::Resource
  attributes :output, :state, :started_at, :finished_at, :stream_id

  belongs_to :stream

  def output
    @model.output_content_split
  end

  def state
    @model.aasm_state
  end
end
