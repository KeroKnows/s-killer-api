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
            status: :bad_request,
            message: "in Request::Query #{e}"
          )
        )
      end

      # Validate input query
      def validate(query)
        puts "validating"
        if QUERY_REGEX.match?(query)
          puts "correct"
          return @params
        end
        puts "wrong"
      end
      
    end
  end
end