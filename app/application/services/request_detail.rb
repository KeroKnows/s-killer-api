# frozen_string_literal: true

require 'dry/transaction'

module Skiller
  module Service
    # Get job details with the given job id
    # :reek:TooManyStatements { max_statements: 7 } for Success/Failure and rescued statements
    class RequestDetail
      include Dry::Transaction

      step :collect_detail
      step :to_response_object

      private

      # :reek:UncommunicativeVariableName for rescued error
      def collect_detail(job_id)
        job = Repository::For.klass(Entity::Job).find_db_id(job_id)

        if job
          job.is_full ? Success(job) : Failure(Response::ApiResult.new(status: :cannot_process, message: 'Lack of full information'))
        else
          Failure(Response::ApiResult.new(status: :bad_request, message: "Job##{job_id} not found. Please request it in advance"))
        end
      rescue StandardError => e
        Failure(Response::ApiResult.new(status: :internal_error, message: "Fail to get job info from database: #{e}"))
      end

      # Pass to response object
      # :reek:UncommunicativeVariableName for rescued error
      def to_response_object(job)
        result_response = Response::Detail.new(job.db_id,
                                               job.title,
                                               job.description,
                                               job.location,
                                               job.salary,
                                               job.url)
        Success(Response::ApiResult.new(status: :ok, message: result_response))
      rescue StandardError => e
        Failure(Response::ApiResult.new(status: :internal_error, message: "Fail to map to detail object: #{e}"))
      end
    end
  end
end
