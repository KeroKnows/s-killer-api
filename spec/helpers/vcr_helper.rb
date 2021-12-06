# frozen_string_literal: true

require_relative '../spec_helper'

module Skiller
  # provide spec utility functions of VCR
  # :reek:TooManyStatements for serial configuration
  module VcrHelper
    CASSETTES_FOLDER = 'spec/fixtures/cassettes'
    REED_CASSETTE = 'reed_api'
    FREECURRENCY_CASSETTE = 'freecurrency_api'
    INTEGRATION_CASSETTE = 'integration'

    def self.setup_vcr
      VCR.configure do |config|
        config.cassette_library_dir = CASSETTES_FOLDER
        config.hook_into :webmock
        config.ignore_localhost = true # for acceptance tests
      end
    end

    def self.configure_reed
      VCR.configure do |config|
        config.filter_sensitive_data('<REED_TOKEN>') { CREDENTIALS }
        config.filter_sensitive_data('<REED_TOKEN_ESC>') { CGI.escape(CREDENTIALS) }

        # This looks ridiculous but - yes, our reed tests depend on the frecurrency api.
        config.filter_sensitive_data('<FREECURRENCY_API_KEY>') { FREECURRENCY_API_KEY }
        config.filter_sensitive_data('<FREECURRENCY_API_KEY_ESC>') { CGI.escape(FREECURRENCY_API_KEY) }
      end

      VCR.insert_cassette REED_CASSETTE,
                          record: :new_episodes,
                          match_requests_on: %i[method uri headers]
    end

    def self.configure_currency
      VCR.configure do |config|
        config.filter_sensitive_data('<FREECURRENCY_API_KEY>') { FREECURRENCY_API_KEY }
        config.filter_sensitive_data('<FREECURRENCY_API_KEY_ESC>') { CGI.escape(FREECURRENCY_API_KEY) }
      end

      VCR.insert_cassette FREECURRENCY_CASSETTE,
                          record: :new_episodes,
                          match_requests_on: %i[method uri headers]
    end

    def self.configure_integration
      VCR.configure do |config|
        config.filter_sensitive_data('<REED_TOKEN>') { CREDENTIALS }
        config.filter_sensitive_data('<REED_TOKEN_ESC>') { CGI.escape(CREDENTIALS) }
        config.filter_sensitive_data('<FREECURRENCY_API_KEY>') { FREECURRENCY_API_KEY }
        config.filter_sensitive_data('<FREECURRENCY_API_KEY_ESC>') { CGI.escape(FREECURRENCY_API_KEY) }
      end

      VCR.insert_cassette INTEGRATION_CASSETTE,
                          record: :new_episodes,
                          match_requests_on: %i[method uri headers]
    end

    def self.eject_vcr
      VCR.eject_cassette
    end
  end
end
