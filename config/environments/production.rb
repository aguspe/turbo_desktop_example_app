require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.public_file_server.headers = { "Cache-Control" => "public, max-age=#{1.year.to_i}" }
  config.force_ssl = true
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_tags = [:request_id]
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.active_record.dump_schema_after_migration = false
  config.active_support.report_deprecations = false
end
