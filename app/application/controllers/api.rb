# frozen_string_literal: true

require 'roda'

module Skiller
  # Web Application for S-killer
  class App < Roda
    plugin :halt
    plugin :flash

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
        router.is do
          # GET /api/v1?query={}
          router.get do
            skill_analysis = Service::AnalyzeSkills.new.call(router.params)
            jobskill = skill_analysis.value!
          end
        end
      end
    end
  end
end
