module AuthenticationHelper

  protected

  def current_user
    @current_user
  end

  def jwt_secret
    Rails.configuration.x.demo_mode ? Rails.application.secret_key_base : ENV.fetch('JWT_SECRET')
  end

  def authenticate
    authenticate_or_request_with_http_token do |token, _options|
      begin
        verified_token = JWT.decode token, jwt_secret, true, {
          algorithm: 'HS512'
        }
        user_id = verified_token.first['sub']

        @user = @current_user = User.find(user_id)
      rescue
        nil
      end
    end
  end
end
