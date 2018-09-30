class Api::UserResource < JSONAPI::Resource
  attributes :email, :github_login, :github_avatar_url
end
