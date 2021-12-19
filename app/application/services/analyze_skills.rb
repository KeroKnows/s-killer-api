# frozen_string_literal: true

require 'dry/transaction'
require 'concurrent'

require_relative 'utils/analyze_skills_util'

module Skiller
  module Service
    # request the jobs related to given query, and analyze the skillset from it
    # :reek:TooManyStatements { max_statements: 7 } for Success/Failure and rescued statements
    class AnalyzeSkills
      include Dry::Transaction

      # [ TODO ] analyze skillset from more data
      ANALYZE_LEN = 10

      step :parse_request
      step :collect_jobs
      step :concurrent_process_jobs
      step :collect_skills
      step :validate_skills_length
      step :calculate_salary_distribution
      step :to_response_object

      private

      EXTRACT_ERR = 'Could not extract skills'
      PROCESSING_MSG = 'Processing the extraction request'

      CONFIG = Skiller::App.config
      SQS = Skiller::Messaging::Queue.new(CONFIG.EXTRACTOR_QUEUE_URL, CONFIG)

      # Check if the previous validation passes
      def parse_request(input)
        if input.success?
          query = input.value!
          Success(query: query)
        else
          failure = input.failure
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

      # :reek:TooManyStatements
      # :reek:UncommunicativeVariableName for rescued error
      def concurrent_process_jobs(input)
        analyzed_jobs = input[:jobs][..ANALYZE_LEN]
        if Utility.jobs_have_skills(analyzed_jobs)
          input[:analyzed_jobs] = analyzed_jobs
          return Success(input)
        end
        Utility.extract_skills_with_worker(analyzed_jobs)
        Failure(Response::ApiResult.new(status: :processing, message: PROCESSING_MSG))
      rescue StandardError => e
        puts [e.inspect, e.backtrace].flatten.join("\n")
        Failure(Response::ApiResult.new(status: :internal_error, message: EXTRACT_ERR))
      end

      def collect_skills(input)
        analyzed_jobs = input[:analyzed_jobs]
        input[:jobs][..ANALYZE_LEN] = analyzed_jobs
        input[:skills] = Utility.find_skills_by_jobs(analyzed_jobs)
        Success(input)
      end

      # Collect skills from database if the query has been searched;
      # otherwise, the entities will be created by mappers and stored into the database
      # :reek:UncommunicativeVariableName for rescued error
      def validate_skills_length(input)
        if input[:skills].length.zero?
          Failure(
            Response::ApiResult.new(status: :internal_error, message: "No skills are extracted from #{input[:query]}")
          )
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

      # Store the query-job
      # Note that this MUST be executed as the last step,
      #   when the jobs and skills are all correctly extracted,
      #   or the skills of new jobs will not be analyzed forever
      # :reek:UncommunicativeVariableName for rescued error
      def store_query_to_db(input)
        Repository::QueriesJobs.find_or_create(input[:query],
                                               input[:jobs].map(&:db_id))
        Success(input)
      rescue StandardError => e
        Failure(Response::ApiResult.new(status: :internal_error, message: "Fail to store query result: #{e}"))
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
