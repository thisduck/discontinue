class Api::RepositoryResource < JSONAPI::Resource
  attributes :integration_id, :full_name, :name, :url, :config, :stream_configs
end
