require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Discontinue
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2
    # to redirect 404 to ember app
    config.exceptions_app = self.routes

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Don't generate system test files.
    config.generators.system_tests = nil
    config.active_job.queue_adapter = :delayed_job

    # config.middleware.use(
    #   ExceptionNotification::Rack,
    #   :email => {
    #     # :deliver_with => :deliver, # Rails >= 4.2.1 do not need this option since it defaults to :deliver_now
    #     :email_prefix => "[Discontinue Exception #{Rails.env}] ",
    #     :sender_address => %{"notifier" <notifier@example.com>},
    #     :exception_recipients => %w{adnan.ali@gmail.com}
    #   }
    # )

  end
end
