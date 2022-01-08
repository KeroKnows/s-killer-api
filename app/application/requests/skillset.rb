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
        params = parse_param_string(param_string)
        if valid?(params)
          Success({ 'skillset' => params['name'], 'location' => params.fetch('location', ['all']).first,
                    'job_level' => params.fetch('job_level', ['all']).first })
        else
          Failure(Response::ApiResult.new(status: :cannot_process, message: "Invalid skillset: #{param_string}"))
        end
      rescue StandardError => e
        Failure(Response::ApiResult.new(status: :internal_error, message: "Fail to validate skillset: #{e}"))
      end

      # :reek:UtilityFunction because it is a utility function
      def valid?(params)
        params.key?('name')
      end

      # :reek:UtilityFunction because it is a utility function
      # :reek:DuplicateMethodCall
      # :reek:TooManyStatements
      def parse_param_string(param_string)
        params = {}
        param_string.split('&').each do |param|
          key, val = param.split('=')
          params[key] ||= []
          params[key] << val
        end
        params
      end
    end
  end
end
