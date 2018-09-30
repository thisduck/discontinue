# frozen_string_literal: true

class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token
  include AuthenticationHelper

  before_action :authenticate
end
