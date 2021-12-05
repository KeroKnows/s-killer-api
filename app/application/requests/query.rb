# frozen_string_literal: true

require 'base64'
require 'dry/monads/result'
require 'json'

module Skiller
  module Request
    class Query
      include Dry::Monads::Result::Mixin

      QUERY_REGEX = /^(?!\s)[a-zA-Z ]+/

      attr_reader :params

      def initialize(params)
        @params = params
      end

      def call
        Success(
          # JSON.parse(decode(@params['query']))
          validate(@params['query'])
        )
      rescue StandardError => e
        Failure(
          Response::ApiResult.new(
            status: :cannot_process,
            message: "#{e}"
          )
        )
      end

      # Validate input query
      def validate(query)
        if QUERY_REGEX.match?(query)
          return @params
        end
        raise("Validation Error")
      end
      
    end
  end
end