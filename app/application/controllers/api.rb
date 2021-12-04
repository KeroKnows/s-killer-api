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
            query_request = Request::Query.new(router.params).call()
            # result = Service::AnalyzeSkills.new.call(query_request: query_request)
            result = Service::AnalyzeSkills.new.call(query_request)


            Representer::For.new(result).status_and_body(response)
          end
        end
      end
    end
  end
end
