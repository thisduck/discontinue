require 'github_api'
class Account < ApplicationRecord
  has_and_belongs_to_many :users
  has_many :repositories

  def installation
    client = GithubApi.client

    client.installation(
      integration_installation_id.to_i, 
      accept: 'application/vnd.github.machine-man-preview+json', 
      headers: {"Authorization" => "Bearer #{GithubApi.jwt}"}
    )
  end

  def access_token
    @access_token ||= 
      begin
        href = installation.rels[:access_tokens].href
        response = HTTParty.post(
          href,

          headers: {
            "User-Agent" => "Discontinue App",
            "Authorization" => "Bearer #{GithubApi.jwt}",
            "Accept" => "application/vnd.github.machine-man-preview+json"
          }

        )
        response["token"]
      end
  end

  def client
    @client ||= Octokit::Client.new(access_token: access_token)
  end
end
