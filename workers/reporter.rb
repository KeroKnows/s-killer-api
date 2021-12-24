# frozen_string_literal: true

require_relative 'progress_publisher'

module SkillExtractor
  # Reports job progress to client
  class JobReporter
    attr_accessor :job

    def initialize(request_json, config)
      extract_request = Skiller::Representer::ExtractRequest
        .new(OpenStruct.new)
        .from_json(request_json)

      @job = extract_request.job
      @publisher = ProgressPublisher.new(config, extract_request.id) # this is channel id
    end

    def report(msg)
      @publisher.publish(msg)
    end

    def report_each_second(seconds, &operation)
      seconds.times do
        sleep(1)
        report(operation.call)
      end
    end
  end
end