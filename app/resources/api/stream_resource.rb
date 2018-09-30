class Api::StreamResource < JSONAPI::Resource
  attributes :name, :state

  belongs_to :build
  has_many :boxes

  def state
    @model.aasm_state
  end
end
