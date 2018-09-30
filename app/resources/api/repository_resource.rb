class Api::RepositoryResource < JSONAPI::Resource
  attributes :github_id, :name, :github_url, :setup_commands
end
