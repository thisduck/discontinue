class Api::BuildRequestResource < JSONAPI::Resource
  include BuildResourceConcern

  attributes :last_build_id

  has_one :last_build, class_name: "Build", always_include_linkage_data: true

  def self.records(options = {})
    context = options[:context]
    context[:current_user].build_requests
  end

  def last_build_id
    @model.builds.last.try :id
  end

end
