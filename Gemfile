# frozen_string_literal: true

source 'https://rubygems.org'
ruby File.read('.ruby-version').strip

# Developing tools
gem 'pry', '~> 0.13.1'

# Web App
gem 'figaro', '~> 1.2'
gem 'puma', '~> 5.5'
gem 'roda', '~> 3.49'
gem 'slim', '~> 4.1'

# Presentation layer
gem 'multi_json'
gem 'roar'

# Database
gem 'hirb', '~> 0'
gem 'hirb-unicode', '~> 0'
gem 'sequel', '~> 5.5'

group :development, :test do
  gem 'sqlite3', '~> 1.4'
end

# Production
group :production do
  gem 'pg'
end

# Validation
gem 'dry-struct', '~> 1.4'
gem 'dry-transaction', '~> 0.13'
gem 'dry-types', '~> 1.5'
gem 'dry-validation', '~> 1.7'

# Networking
gem 'http', '~> 5.0'

# Testing
group :test do
  gem 'minitest', '~> 5.0'
  gem 'minitest-rg', '~> 5.0'
  gem 'page-object', '~> 2.3'
  gem 'rack-test'
  gem 'simplecov', '~> 0'
  gem 'vcr', '~> 6.0'
  gem 'watir', '~> 7.0'
  gem 'webdrivers', '~> 5.0'
  gem 'webmock', '~> 3.0'
end

# Utilities
gem 'rake'

def os_is(pattern)
  RbConfig::CONFIG['host_os'] =~ pattern ? true : false
end
group :development do
  gem 'rb-fsevent', platforms: :ruby, install_if: os_is(/darwin/)
  gem 'rb-kqueue', platforms: :ruby, install_if: os_is(/linux/)
  gem 'rerun'
end
gem 'nokogiri', '~> 1.12'

# Code Quality
gem 'flog'
gem 'reek'
gem 'rubocop'

# Caching
gem 'rack-cache', '~> 1.13'
gem 'redis', '~> 4.5'
gem 'redis-rack-cache', '~> 2.2'