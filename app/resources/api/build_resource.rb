class Api::BuildResource < JSONAPI::Resource
  attributes :branch, :sha, :build_request_id, :state, :hook_hash, :events, :repository_id

  belongs_to :build_request
  belongs_to :repository

  def state
    @model.aasm_state
  end

  def events
    @model.aasm.events(permitted: true).map(&:name)
  end
end
