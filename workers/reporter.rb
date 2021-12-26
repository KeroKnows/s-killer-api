# frozen_string_literal: true

require_relative 'progress_publisher'

module SkillExtractor
  # Reports job progress to client
  class JobReporter
    attr_reader :job

    def initialize(request_json, config)
      extract_request = Skiller::Representer::ExtractRequest
                        .new(OpenStruct.new)
                        .from_json(request_json)

      @job = extract_request.job
      @publisher = ProgressPublisher.new(config, extract_request.id) # this is channel id
    end

    # Report progress using publisher
    def report(msg)
      @publisher.publish(msg)
    end
  end
end
