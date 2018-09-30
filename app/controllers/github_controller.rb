require 'github_push_hook'

class GithubController < ApplicationController
  GITHUB_WEBHOOK_SECRET_TOKEN = "CoolBeansAreSoCoool"
  skip_before_action :authenticate, only: [:webhook]
  before_action :verify_github_webhook, only: [:webhook]

  def webhook
    hook = GithubPushHook.new(params)
    repo = Repository.where(github_id: hook.repository_id).first

    if hook.branch.present? && hook.sha.present?
      BuildRequest.add_request(
        branch: hook.branch,
        sha: hook.sha,
        hook_hash: hook.hash,
        repository: repo
      )
    end

    render plain: ''
  end

  def repositories
    render json: current_user.github.organizations.first.rels[:repos].get.data.collect(&:to_hash)
  end

  protected

  def verify_github_webhook
    payload_body = request.body.read
    hub_signature = request.env['HTTP_X_HUB_SIGNATURE']
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), GITHUB_WEBHOOK_SECRET_TOKEN, payload_body)

    unless Rack::Utils.secure_compare(signature, hub_signature)
      render json: {}, status: :unauthorized
      return false
    end
  end
end
