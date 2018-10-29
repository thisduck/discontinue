class ApiController < JSONAPI::ResourceController
  include AuthenticationHelper
  before_action :authenticate
end
