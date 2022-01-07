# frozen_string_literal: true

require 'dry/transaction'
require 'concurrent'

require_relative 'utils/analyze_skills_util'

module Skiller
  module Service
    # request the jobs related to given skillset, and analyze the skillset from it
    # :reek:TooManyStatements { max_statements: 7 } for Success/Failure and rescued statements
    class AnalyzeJobs
      include Dry::Transaction

      step :parse_request
      step :collect_skills
      step :collect_jobs
      step :filter_jobs_by_location
      step :calculate_salary_distribution
      step :to_response_object

      private

      # Check if the previous validation passes
      def parse_request(input)
        if input.success?
          # skillset is an array of skill names
          params = input.value!
          Success(skillset: params['skillset'].map(&:downcase), location: params['location'])
        else
          failure = input.failure
          Failure(Response::ApiResult.new(status: failure.status, message: failure.message))
        end
      end

      def collect_skills(input)
        skillset = input[:skillset]
        input[:skills] = Utility.find_skills_by_skillset(skillset)

        if input[:skills].length.zero?
          Failure(
            Response::ApiResult.new(status: :internal_error,
                                    message: "No skills are extracted from #{skillset}")
          )
        else
          Success(input)
        end
      end

      # Collect jobs from database if the skillset has been searched;
      # otherwise, the entites will be created by mappers stored into the database
      # :reek:UncommunicativeVariableName for rescued error
      def collect_jobs(input)
        skills = input[:skills]
        input[:jobs] = Utility.find_jobs_by_skills(skills)

        if input[:jobs].length.zero?
          Failure(Response::ApiResult.new(status: :cannot_process,
                                          message: "No job found with skillset #{input[:skillset]}"))
        else
          Success(input)
        end
      rescue StandardError => e
        Failure(Response::ApiResult.new(status: :internal_error, message: "Fail to collect jobs: #{e}"))
      end

      # :reek:UncommunicativeVariableName for rescued error
      def filter_jobs_by_location(input)
        location = input[:location]
        input[:jobs] = input[:jobs].select { |job| job.location.downcase == location.downcase } if location != 'all'
        Success(input)
      rescue StandardError => e
        Failure(Response::ApiResult.new(status: :internal_error, message: "Fail to filter jobs by location: #{e}"))
      end

      # Analyze the salary distribution from all related jobs
      # :reek:UncommunicativeVariableName for rescued error
      def calculate_salary_distribution(input)
        all_salary = input[:jobs].map(&:salary)
        input[:salary_dist] = Entity::SalaryDistribution.new(all_salary)
        Success(input)
      rescue StandardError => e
        Failure(Response::ApiResult.new(status: :internal_error, message: "Fail to analyze salary distribution: #{e}"))
      end

      # Pass to response object
      # :reek:UncommunicativeVariableName for rescued error
      def to_response_object(input)
        result_response = Response::Result.new(input[:skillset], input[:jobs], input[:skills], input[:salary_dist])
        Success(Response::ApiResult.new(status: :ok, message: result_response))
      rescue StandardError => e
        Failure(Response::ApiResult.new(status: :internal_error, message: "Fail to map to response object: #{e}"))
      end
    end
  end
end
