require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Pglite
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib #{config.root}/lib/reports #{config.root}/lib/tasks #{config.root}/app/datatables})

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'New Delhi'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    config.active_record.whitelist_attributes = true
    config.active_record.default_timezone = :local

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    #config.assets.paths << Rails.root.join("app", "assets", "font")

    #config.exceptions_app = self.routes

    config.use_ssl = true
    config.ssl_port = 3001
    config.force_ssl = true


    # Peregrine Guard  specific settings...
    config.peregrine_policyfile = "/usr/local/etc/pgguard/policy.xml"
    config.peregrine_configfile = "/usr/local/etc/pgguard/pgguardconfig.xml"
    config.peregrine_policyfile_dtd = "/usr/local/etc/pgguard/pg_policy.dtd"
    config.peregrine_pgguard_pidfile = "/usr/local/var/pgguard/pgguard.pid"
    config.peregrine_adconfigfile = "/usr/local/etc/i7ADPlugin/config.xml"
    config.peregrine_cisco_acl_configfile = "/usr/local/etc/pgguard/ciscoconfig.xml"
    config.peregrine_plugin_maas360_config = "/usr/local/var/plugin/Maas360Plugin/config.xml"
    config.peregrine_pgguard_alert_cmd = "cat #{config.peregrine_pgguard_pidfile} | xargs kill -s ALRM"
    config.peregrine_pgguard_SIGUSR_cmd = "cat #{config.peregrine_pgguard_pidfile} | xargs kill -s USR1"

    config.i7alerts_ignore_classes=%w[0, 2, 3, 4, 5, 7, 8, 12]
  

    #
    # Default auth is using the local store (database table)
    #
    config.authentication = "Local"
    if File.exist?(config.peregrine_configfile)
      xmlfile = File.new(config.peregrine_configfile)
      configHash = Hash.from_xml(xmlfile)
      if (configHash['pgguard'].nil? || configHash['pgguard']['authentication'].nil? || configHash['pgguard']['authentication']['ldap'].nil?)
        config.authentication = "Local"
      else
        config.authentication = "ActiveDirectory"
      end
    end

  end

  def self.config
    Application.config
  end
end
