# frozen_string_literal: true

require 'github_auth'

class SessionController < ApplicationController
  before_action :authenticate, only: [:current]

  def create
    access_token = GithubAuth.new(params[:code]).access_token!
    client = Octokit::Client.new(access_token: access_token)

    begin
      user = User.where(github_auth_id: client.user.id).first
      if user.blank?
        user = User.where(email: client.user.email).first
        user.update_attributes(github_auth_id: client.user.id) if user.present?
      end

      if user.blank?
        user = User.create(email: client.user.email, github_auth_id: client.user.id, password: 'SomeRandomPass123')
      end
      user.update_attributes(access_token: access_token)

      payload = {
        data: {
          id: user.id.to_s,
          email: user.email,
        },
        sub: user.id.to_s,
        exp: 2.weeks.from_now.to_i
      }

      token = JWT.encode payload, ENV['JWT_SECRET'], 'HS512'

      render json: { token: token }
    rescue StandardError
      render json: {}, status: :unauthorized
    end
  end

  def current
    serializer = JSONAPI::ResourceSerializer.new(UserResource)
    render json: serializer.serialize_to_hash(UserResource.new(@user, nil))
  end
end
