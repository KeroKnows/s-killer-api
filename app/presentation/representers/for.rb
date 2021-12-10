# frozen_string_literal: true

require_relative '../responses/init'

require_relative 'http_response_representer'
require_relative 'result_representer'

module Skiller
  module Representer
    # Returns appropriate representer for response object
    class For
      REP_KLASS = {
        Response::Result => Result,
        String => HttpResponse
      }.freeze

      attr_reader :status_rep, :body_rep

      def initialize(result)
        if result.failure?
          @status_rep = Representer::HttpResponse.new(result.failure)
          @body_rep = @status_rep
        else
          value = result.value!
          message = value.message
          @status_rep = Representer::HttpResponse.new(value)
          @body_rep = REP_KLASS[message.class].new(message)
        end
      end

      def http_status_code
        @status_rep.http_status_code
      end

      def to_json(*args)
        @body_rep.to_json(*args)
      end

      def status_and_body(response)
        response.status = http_status_code
        to_json
      end
    end
  end
end
