# frozen_string_literal: true

class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token

  protected

  def authenticate
    authenticate_or_request_with_http_token do |token, _options|
      verified_token = JWT.decode token, ENV['JWT_SECRET'], true, algorithm: 'HS512'
      user_id = verified_token.first['sub']

      @user = User.find(user_id)
    end
  end
end
