# frozen_string_literal: true

require 'http'

module SkillExtractor
  # Publishes progress as percent to Faye endpoint
  class ProgressPublisher
    def initialize(config, channel_id)
      @config = config
      @channel_id = channel_id
    end

    def publish(message)
      print "Progress: #{message} "
      print "[post: http://0.0.0.0:9090/faye] "
      response = HTTP.headers(content_type: 'application/json')
        .post(
          "http://0.0.0.0:9090/faye",
          body: message_body(message)
        )
      puts "(#{response.status})"
      puts message_body(message)
    rescue HTTP::ConnectionError
      puts '(Faye server not found - progress not sent)'
    end

    private

    def message_body(message)
      { 
        channel: "/#{@channel_id}",
        data: {
          progress: message,
          currently_analyzed: message,
          total_to_analyze: 10,
        }
      }.to_json
    end
  end
end