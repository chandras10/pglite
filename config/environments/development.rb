Pglite::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  config.active_record.auto_explain_threshold_in_seconds = 0.5

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  # Peregrine Guard Policy file residence
  config.peregrine_policyfile = "/usr/local/etc/pgguard/policy.xml"
  config.peregrine_ldapfile = "/usr/local/etc/pgguard/ldap.yml"
  config.peregrine_configfile = "/usr/local/etc/pgguard/pgguardconfig.xml"
  config.peregrine_policyfile_dtd = "/usr/local/etc/pgguard/pg_policy.dtd"
  config.peregrine_pgguard_pidfile = "/usr/local/var/pgguard/pgguard.pid"
  config.peregrine_adconfigfile = "/usr/local/etc/i7ADPlugin/config.xml"
  config.peregrine_pgguard_alert_cmd = "cat #{config.peregrine_pgguard_pidfile} | xargs kill -s ALRM"

  config.i7alerts_ignore_classes=%w[0, 4, 5, 6, 7]
  
  config.use_ssl = true
  config.ssl_port = 3001
  config.force_ssl = true


end
