# frozen_string_literal: true

module Skiller
  # An utility class that handle response status in analyze_skills_spec
  class ServiceSpecUtility
    SERVICE = Skiller::Service::AnalyzeSkills.new

    def self.wait_for_processing(query_form)
      request = { query_request: query_form, request_id: 0 }
      sleeping_time = 0
      while processing?(result = SERVICE.call(request)) && (sleeping_time < 30)
        sleep 10
        sleeping_time += 10
      end
      result
    end

    def self.cannot_process?(result)
      result.failure? && result.failure.status == :cannot_process
    end

    def self.call_and_processing?(query_form)
      processing?(SERVICE.call(query_form))
    end

    def self.processing?(result)
      result.failure? && result.failure.status == :processing
    end
  end
end
