# frozen_string_literal: true

require 'dry/transaction'

module Skiller
  module Service
    # Get job details with the given job id
    # :reek:TooManyStatements { max_statements: 7 } for Success/Failure and rescued statements
    class RequestDetail
      include Dry::Transaction

      step :collect_detail
      step :validate_data
      step :to_response_object

      private

      # Collect job from database
      # :reek:UncommunicativeVariableName for rescued error
      def collect_detail(job_id)
        job = Repository::For.klass(Entity::Job).find_db_id(job_id)

        if job
          Success(job)
        else
          Failure(Response::ApiResult.new(status: :not_found,
                                          message: "Job##{job_id} not found. Please request it in advance"))
        end
      rescue StandardError => e
        Failure(Response::ApiResult.new(status: :internal_error,
                                        message: "Fail to get job info from database: #{e}"))
      end

      # Check if the job has full information
      # :reek:UncommunicativeVariableName for rescued error
      def validate_data(job)
        if job.is_full
          Success(job)
        else
          Failure(Response::ApiResult.new(status: :cannot_process, message: 'Lack of full information.'))
        end
      rescue StandardError => e
        Failure(Response::ApiResult.new(status: :internal_error,
                                        message: "Fail to validate job detail: #{e}"))
      end

      # Pass to response object
      # :reek:UncommunicativeVariableName for rescued error
      def to_response_object(job)
        result_response = Response::Detail.new(job.db_id,
                                               job.title,
                                               job.description,
                                               job.location,
                                               job.salary,
                                               job.url,
                                               job.job_level)
        Success(Response::ApiResult.new(status: :ok, message: result_response))
      rescue StandardError => e
        Failure(Response::ApiResult.new(status: :internal_error,
                                        message: "Fail to map to detail object: #{e}"))
      end
    end
  end
end
