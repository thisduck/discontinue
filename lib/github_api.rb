require 'openssl'
require 'jwt'

class GithubApi
  def self.client
    client = Octokit::Client.new(
      client_id: ENV['GITHUB_APP_CLIENT_ID'],
      client_secret: ENV['GITHUB_APP_CLIENT_SECRET'],
    )
  end

  def self.jwt
    # Private key contents
    private_pem = ENV['GITHUB_PEM']
    private_pem ||= File.read(ENV['GITHUB_PEM_PATH'])
    private_key = OpenSSL::PKey::RSA.new(private_pem)

    # Generate the JWT
    payload = {
      # issued at time
      iat: Time.now.to_i,
      # JWT expiration time (10 minute maximum)
      exp: Time.now.to_i + (10 * 60),
      # GitHub App's identifier
      iss: ENV['GITHUB_APP_ID'].to_i
    }

    jwt = JWT.encode(payload, private_key, "RS256")
  end
end

