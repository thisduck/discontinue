class Api::BuildRequestResource < JSONAPI::Resource
  attributes :branch, :sha, :repository_id, :state, :hook_hash, :events, :last_build_id, :created_at
  has_one :repository
  has_one :last_build, class_name: "Build", always_include_linkage_data: true

  paginator :paged
  filter :branch, apply: ->(records, value, _options) {
    records.where("branch like ?", "%#{value[0]}%")
  }

  def self.records(options = {})
    context = options[:context]
    context[:current_user].build_requests
  end

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
