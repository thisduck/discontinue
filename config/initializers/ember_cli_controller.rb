Rails.application.config.to_prepare do
  EmberCli::EmberController.skip_before_action :authenticate, raise: false
end
