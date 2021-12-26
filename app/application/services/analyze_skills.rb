# frozen_string_literal: true

require 'dry/transaction'
require 'concurrent'

require_relative 'utils/analyze_skills_util'

module Skiller
  module Service
    # request the jobs related to given query, and analyze the skillset from it
    class AnalyzeSkills
      include Dry::Transaction

      # [ TODO ] analyze skillset from more data
      ANALYZE_LEN = 10

      step :parse_request
      step :collect_jobs
      step :concurrent_process_jobs
      step :collect_skills
      step :calculate_salary_distribution
      step :to_response_object

      private

      # Check if the previous validation passes
      def parse_request(input)
        request = input[:query_request]
        if request.success?
          query = request.value!
          Success(query: query, request_id: input[:request_id])
        else
          failure = request.failure
          Failure(Response::ApiResult.new(status: failure.status, message: failure.message))
        end
      end

      # Collect jobs from database if the query has been searched;
      # otherwise, the entites will be created by mappers stored into the database
      # :reek:UncommunicativeVariableName for rescued error
      def collect_jobs(input)
        input[:jobs] = Utility.search_jobs(input)

        if input[:jobs].length.zero?
          Failure(Response::ApiResult.new(status: :cannot_process, message: "No job found with query #{input[:query]}"))
        else
          Success(input)
        end
      rescue StandardError => e
        Failure(Response::ApiResult.new(status: :internal_error, message: "Fail to collect jobs: #{e}"))
      end

      # Check if all jobs are analyzed before
      # :reek:UncommunicativeVariableName for rescued error
      def concurrent_process_jobs(input)
        jobs = input[:jobs][...ANALYZE_LEN]
        return Success(input) if Utility.all_jobs_analyzed?(jobs)

        request_id = input[:request_id]
        Utility.extract_skills_with_worker(jobs, request_id)
        Failure(Response::ApiResult.new(status: :processing,
                                        message: { message: 'Processing the extraction request',
                                                   request_id: request_id }))
      rescue StandardError => e
        Failure(Response::ApiResult.new(status: :internal_error, message: "Fail to process the jobs: #{e}"))
      end

      # Collect skills from database if the query has been searched;
      #   otherwise, the entities will be created by mappers and stored into the database
      # :reek:UncommunicativeVariableName for rescued error
      def collect_skills(input)
        input[:skills] = Utility.find_skills_by_jobs(input[:jobs])
        if input[:skills].length.zero?
          Failure(Response::ApiResult.new(status: :internal_error,
                                          message: "No skills are extracted from #{input[:query]}"))
        else
          Success(input)
        end
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
        result_response = Response::Result.new(input[:query], input[:jobs], input[:skills], input[:salary_dist])
        Success(Response::ApiResult.new(status: :ok, message: result_response))
      rescue StandardError => e
        Failure(Response::ApiResult.new(status: :internal_error, message: "Fail to map to response object: #{e}"))
      end
    end
  end
end
