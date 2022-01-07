# frozen_string_literal: true

require 'base64'
require 'dry/monads/result'
require 'json'

module Skiller
  module Request
    # Request object for query
    class Query
      include Dry::Monads::Result::Mixin

      QUERY_REGEX = /^(?!\s)[a-zA-Z ]+/

      # Validate the query format
      # :reek:UncommunicativeVariableName for rescued error
      def call(params)
        query = params['query']
        if QUERY_REGEX.match?(query)
          Success({ 'query' => query, 'location' => params.fetch('location', 'all') })
        else
          Failure(Response::ApiResult.new(status: :cannot_process, message: "Invalid query: #{query}"))
        end
      rescue StandardError => e
        Failure(Response::ApiResult.new(status: :internal_error, message: "Fail to vallidate query: #{e}"))
      end
    end
  end
end
