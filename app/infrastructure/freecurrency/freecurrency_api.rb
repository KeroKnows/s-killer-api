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
      EXPIRE_TIME = 1 # expire after a day

      HTTP_ERROR = {
        429 => FreeCurrency::Errors::InvalidApiKey,
        302 => FreeCurrency::Errors::InvalidCurrency,
        404 => FreeCurrency::Errors::NotFound,
        500 => FreeCurrency::Errors::InternalError
      }.freeze

      def initialize(api_key, cache_class = Skiller::Cache::FileClient, cache_path = nil)
        @api_key = api_key
        cache_path ||= CACHE_FILE
        @cache = cache_class.new(cache_path)
      end

      # send request to freecurrency API
      def exchange_rates(currency)
        request_rates(currency) if !@cache.exist?(currency) || @cache.expire?(currency)
        @cache.get(currency)
      end

      # request current currency rate from API
      def request_rates(currency)
        response = HTTP.get(API_PATH, params: { apikey: @api_key, base_currency: currency })
        result = HttpResponse.new(response, HTTP_ERROR).parse
        @cache.set(currency, result, EXPIRE_TIME)
        result
      end
    end
  end
end
