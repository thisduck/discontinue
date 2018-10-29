class Api::UserResource < JSONAPI::Resource
  attributes :email, :integration_login, :avatar_url
end
