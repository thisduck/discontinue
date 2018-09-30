class Api::BuildRequestResource < JSONAPI::Resource
  attributes :branch, :sha, :repository_id, :state, :hook_hash, :events
  belongs_to :repository

  def state
    @model.aasm_state
  end

  def events
    @model.aasm.events(permitted: true).map(&:name)
  end
end
