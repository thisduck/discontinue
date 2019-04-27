# frozen_string_literal: true

require 'github_auth'

class SessionController < ApplicationController
  skip_before_action :authenticate, only: [:create]

  def create
    begin
      user = find_user(params[:code])
      token = make_token(user)

      render json: { token: token }
    rescue StandardError => e
      puts e.message
      puts e.backtrace
      render json: {}, status: :unauthorized
    end
  end

  def current
    serializer = JSONAPI::ResourceSerializer.new(Api::UserResource)
    render json: serializer.serialize_to_hash(Api::UserResource.new(@user, nil))
  end

  protected

  def find_user(code)
    access_token = GithubAuth.new(code).access_token!
    client = Octokit::Client.new(access_token: access_token)

    github_user = client.user
    user = User.where(
      integration_type: 'github',
      integration_id: github_user.id
    ).first_or_create

    user.update_attributes({
      email: github_user.email,
      access_token: access_token,
      integration_login: github_user.login,
      avatar_url: github_user.avatar_url
    })

    client.organizations.each do |org|
      account = Account.where(
        integration_type: 'github', 
        integration_id: org['id']
      ).first

      next if account.blank?

      unless user.accounts.include?(account)
        user.accounts << account 
        user.save
      end

    end

    # hook up to existing accounts
    

    user
  end

  def make_token(user)
    payload = {
      data: {
        id: user.id.to_s,
        email: user.email,
      },
      sub: user.id.to_s,
      exp: 2.months.from_now.to_i
    }

    JWT.encode payload, ENV['JWT_SECRET'], 'HS512'
  end
end
