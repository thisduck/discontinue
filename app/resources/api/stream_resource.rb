class Api::StreamResource < JSONAPI::Resource
  attributes :name, :state

  belongs_to :build

  def state
    @model.aasm_state
  end
end
