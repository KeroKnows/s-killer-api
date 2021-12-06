# frozen_string_literal: true

require 'http'
require 'forwardable'
require 'yaml'
require_relative '../http_response'

module Skiller
  # Library for freecurrency API Handling
  module FreeCurrency
    # Errors for freecurrency API Handling
    module Errors
      # for HTTP 404 not found
      class NotFound < StandardError; end
      # for HTTP 429 Too many requests (it seems that this API responds with 429 if passing an invalid API key)
      class InvalidApiKey < StandardError; end # rubocop:disable Layout/EmptyLineBetweenDefs
      # for HTTP 302 (it seems that this API responds with 302 if passing an invalid base currency)
      class InvalidCurrency < StandardError; end # rubocop:disable Layout/EmptyLineBetweenDefs
      # for HTTP 500
      class InternalError < StandardError; end # rubocop:disable Layout/EmptyLineBetweenDefs
    end

    # freecurrency API
    class Api
      API_PATH = 'https://freecurrencyapi.net/api/v2/latest'
      CACHE_FILE = File.join(File.dirname(__FILE__), 'rate.cache')
      EXPIRE_TIME = 7 # expire after a week

      HTTP_ERROR = {
        429 => FreeCurrency::Errors::InvalidApiKey,
        302 => FreeCurrency::Errors::InvalidCurrency,
        404 => FreeCurrency::Errors::NotFound,
        500 => FreeCurrency::Errors::InternalError
      }.freeze

      def initialize(api_key)
        @api_key = api_key
        @cache = nil
      end

      # send request to freecurrency API
      def exchange_rates(currency)
        check_cache
        @cache ? @cache['data'] : request_rates(currency)
      end

      # check if the the cache is valid
      def check_cache
        return unless File.exist?(CACHE_FILE)

        cache = YAML.safe_load(File.read(CACHE_FILE))
        @cache = cache if Date.today - Date.parse(cache['date']) < EXPIRE_TIME
      end

      # request current currency rate from API
      def request_rates(currency)
        response = HTTP.get(API_PATH, params: { apikey: @api_key, base_currency: currency })
        result = HttpResponse.new(response, HTTP_ERROR).parse
        data = { 'date' => Date.today.to_s, 'data' => result }
        File.write(CACHE_FILE, data.to_yaml, mode: 'w')
        result
      end
    end
  end
end
