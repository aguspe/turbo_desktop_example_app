source "https://rubygems.org"

ruby ">= 3.1.0"

# Rails framework
gem "rails", "~> 8.0"

# Database
gem "sqlite3", "~> 2.0"

# Web server
gem "puma", "~> 6.0"

# Asset pipeline
gem "propshaft"

# Hotwire
gem "turbo-rails"
gem "stimulus-rails"
gem "importmap-rails"

# Turbo Desktop — gives your Rails app desktop shell awareness
# This gem provides helpers like turbo_desktop_app?, turbo_desktop_only,
# serves the path configuration JSON, and serves the Dev Inspector assets.
# Pulled from the monorepo until it's published to RubyGems.
gem "turbo_desktop-rails",
    git: "https://github.com/aguspe/turbo_desktop.git",
    glob: "turbo_desktop-rails/*.gemspec"

# Reduces boot times through caching
gem "bootsnap", require: false

group :development do
  gem "web-console"
end
