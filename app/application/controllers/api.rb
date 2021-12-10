# frozen_string_literal: true

require 'roda'

module Skiller
  # Web Application for S-killer
  class App < Roda
    plugin :halt

    route do |router|
      response['Content-Type'] = 'application/json'

      # GET / (to Check API alive)
      router.root do
        message = "S-killer API v1 at /api/v1/ in #{App.environment} mode"

        result_response = Representer::HttpResponse.new(
          Response::ApiResult.new(status: :ok, message: message)
        )

        response.status = result_response.http_status_code
        result_response.to_json
      end

      router.on 'api/v1' do
        router.on 'jobs' do
          # GET /api/v1/jobs?query={JOB_TITLE}
          router.get do
            # validate request
            query_request = Request::Query.new.call(router.params)
            result = Service::AnalyzeSkills.new.call(query_request)

            if result.failure?
              failed = Representer::For.new(result)
              router.halt failed.http_status_code, failed.to_json
            end

            # response
            Representer::For.new(result).status_and_body(response)
          end
        end

        router.on 'details' do
          router.is do
            # health check
            Representer::For.new('hello').status_and_body(response)
          end

          router.on Integer do |job_id|
            # GET /details/{JOB_ID}
            job_info = Service::RequestDetail.new.call(job_id)

            if job_info.failure?
              failed = Representer::For.new(job_info)
              router.halt failed.http_status_code, failed.to_json
            end

            # response
            Representer::For.new(job_info).status_and_body(response)
          end
        end
      end
    end
  end
end
