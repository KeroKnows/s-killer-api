# frozen_string_literal: true

require 'dry-struct'
require_relative '../values/salary'

module Skiller
  module Entity
    # Job information from Reed Details API
    class Job < Dry::Struct
      include Dry.Types
      attribute :db_id, Integer.optional
      attribute :job_id, Strict::Integer
      attribute :title, Strict::String
      attribute :description, Strict::String
      attribute :location, Strict::String
      attribute :salary, Skiller::Value::Salary
      attribute :url, String.optional
      attribute :is_full, Strict::Bool
      attribute :is_analyzed, Strict::Bool

      # rubocop:disable Metrics/MethodLength
      def analyzed
        Job.new(
          db_id: db_id,
          job_id: job_id,
          title: title,
          description: description,
          location: location,
          salary: salary,
          url: url,
          is_full: is_full,
          is_analyzed: true
        )
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
