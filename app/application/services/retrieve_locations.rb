# frozen_string_literal: true

require 'dry/transaction'
require 'concurrent'

require_relative 'utils/analyze_skills_util'

module Skiller
  module Service
    # retrive locations from the database
    # :reek:TooManyStatements { max_statements: 7 } for Success/Failure and rescued statements
    class RetrieveLocations
      include Dry::Transaction

      step :retrive_locations

      private

      def retrive_locations
          # skillset is an array of skill names
          locations = Skiller::Repository::Jobs.all.map(&:location).uniq
          if locations.length.zero?
            Failure(Response::ApiResult.new(status: :cannot_process,
                                            message: "No locations in the database"))
          else
            locations_response = Response::Locations.new(locations)
            Success(Response::ApiResult.new(status: :ok, message: locations_response))
        end
      end
    end
  end
end
