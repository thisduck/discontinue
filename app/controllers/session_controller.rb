# frozen_string_literal: true

require 'github_auth'

class SessionController < ApplicationController
  skip_before_action :authenticate, only: [:create]

  def create
    begin
      user = find_user(params[:code])
      token = make_token(user)

      render json: { token: token }
    rescue StandardError
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
    user = User.where(github_auth_id: github_user.id).first
    user = User.where(email: github_user.email).first if user.blank?
    user = User.create!(email: github_user.email) if user.blank?

    user.update_attributes({
      access_token: access_token,
      github_auth_id: github_user.id,
      github_login: github_user.login,
      github_avatar_url: github_user.avatar_url
    })

    user
  end

  def make_token(user)
    payload = {
      data: {
        id: user.id.to_s,
        email: user.email,
      },
      sub: user.id.to_s,
      exp: 2.weeks.from_now.to_i
    }

    JWT.encode payload, ENV['JWT_SECRET'], 'HS512'
  end
end
