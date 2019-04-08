require 'github_push_hook'

class GithubController < ApplicationController
  GITHUB_WEBHOOK_SECRET_TOKEN = "CoolBeansAreSoCoool"
  skip_before_action :authenticate, only: [:webhook]
  before_action :verify_github_webhook, only: [:webhook]

  def webhook
    event = request.env['HTTP_X_GITHUB_EVENT']
    event_handler_class = nil

    begin
      event_handler_class = "GithubEvents::#{event.classify}".constantize
    rescue 
      puts "No GithubEvent for #{event}"
    end

    if event_handler_class
      event_handler = event_handler_class.new(params.as_json)
      event_handler.handle
    end

    render plain: ''
  end

  def repositories
    render json: current_user.github.organizations.first.rels[:repos].get.data.collect(&:to_hash)
  end

  def pull_requests
    repository = Repository.find params[:repository_id]
    render json: repository.account.client.pulls(repository.integration_id.to_i, state: "open").collect(&:to_hash)
  end

  def branches
    repository = Repository.find params[:repository_id]
    render json: repository.account.client.branches(repository.integration_id.to_i).collect(&:to_hash)
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
