class ApiController < JSONAPI::ResourceController
  protect_from_forgery with: :null_session

  include AuthenticationHelper
  before_action :authenticate

  def context
    { current_user: current_user }
  end
end
