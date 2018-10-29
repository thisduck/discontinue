# frozen_string_literal: true

require 'rest-client'
class GithubAuth
  def initialize(code)
    @code = code
  end

  def access_token!
    result = RestClient.post(
      'https://github.com/login/oauth/access_token',
      {
        client_id: ENV['GITHUB_APP_CLIENT_ID'],
        client_secret: ENV['GITHUB_APP_CLIENT_SECRET'],
        code: @code
      },
      accept: :json
    )

    JSON.parse(result)['access_token']
  end
end
