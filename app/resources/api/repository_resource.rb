class Api::RepositoryResource < JSONAPI::Resource
  attributes :integration_id, :full_name, :name, :url, :config, :stream_configs

  def self.records(options = {})
    context = options[:context]
    context[:current_user].repositories
  end
end
