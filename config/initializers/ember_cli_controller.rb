require 'ember_cli/ember_controller'

class EmberCli::EmberController
  skip_before_action :authenticate
end
