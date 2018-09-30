class Api::BuildRequestResource < JSONAPI::Resource
  attributes :branch, :sha, :repository_id, :state, :hook_hash, :events, :last_build_id
  has_one :repository
  has_one :last_build, class_name: "Build", always_include_linkage_data: true

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
