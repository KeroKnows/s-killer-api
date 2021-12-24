# frozen_string_literal: true

require_relative 'progress_publisher'

module SkillExtractor
  # Reports job progress to client
  class JobReporter
    attr_accessor :job

    def initialize(request_json, config)
      # clone_request = CodePraise::Representer::CloneRequest
      #   .new(OpenStruct.new)
      #   .from_json(request_json)

      # job = Skiller::Representer::Job.new(OpenStruct.new).from_json(request_json)
      extract_request = Skiller::Representer::ExtractRequest
        .new(OpenStruct.new)
        .from_json(request_json)

      @job = extract_request.job
      @publisher = ProgressPublisher.new(config, extract_request.id) # this is channel id
      # @project = clone_request.project
      # @publisher = ProgressPublisher.new(config, clone_request.id)
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