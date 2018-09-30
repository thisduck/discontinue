class Api::BuildRequestResource < JSONAPI::Resource
  attributes :branch, :sha, :repository_id, :state, :hook_hash, :events, :last_build_id
  belongs_to :repository

  def last_build_id
    @model.builds.last.try :id
  end

  def state
    @model.aasm_state
  end

  def events
    @model.aasm.events(permitted: true).map(&:name)
  end
end
