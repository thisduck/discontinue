class Api::RepositoryResource < JSONAPI::Resource
  attributes :github_id, :name, :github_url, :config, :stream_configs
end
