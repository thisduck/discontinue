module AuthenticationHelper

  protected

  def current_user
    @current_user
  end

  def authenticate
    authenticate_or_request_with_http_token do |token, _options|
      verified_token = JWT.decode token, ENV['JWT_SECRET'], true, {
        algorithm: 'HS512'
      }
      user_id = verified_token.first['sub']

      @user = @current_user = User.find(user_id)
    end
  end
end
