class ApiController < JSONAPI::ResourceController
  include AuthenticationHelper
  before_action :authenticate

  def context
    {
      current_user: current_user
    }
  end
end
