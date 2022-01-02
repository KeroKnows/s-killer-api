# frozen_string_literal: true

require 'base64'
require 'dry/monads/result'
require 'json'

module Skiller
  module Request
    # Request object for skillset
    class Skillset
      include Dry::Monads::Result::Mixin

      # TODO: design the regex pattern for skillset
      SKILLSET_REGEX = /(&?name=[a-zA-Z ]+)+/

      # Validate the skillset format
      # :reek:UncommunicativeVariableName for rescued error
      def call(param_string)
        if valid?(param_string)
          skillset = parse_param_string(param_string)
          Success(skillset)
        else
          Failure(Response::ApiResult.new(status: :cannot_process, message: "Invalid skillset: #{param_string}"))
        end
      rescue StandardError => e
        Failure(Response::ApiResult.new(status: :internal_error, message: "Fail to validate skillset: #{e}"))
      end

      def valid?(param_string)
        SKILLSET_REGEX.match(param_string)[0]&.length == param_string.length
      end

      def parse_param_string(param_string)
        param_string.split('&').map { |param| param.split('=')[1] }
      end
    end
  end
end
