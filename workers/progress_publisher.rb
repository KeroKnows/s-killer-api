# frozen_string_literal: true

require 'http'

module SkillExtractor
  # Publishes current processing job_title to Faye endpoint
  class ProgressPublisher
    def initialize(config, channel_id)
      @config = config
      @channel_id = channel_id
      @app_host = "#{@config.APP_HOST}/faye".freeze
    end

    # Post a progress to Faye endpoint
    def publish(message)
      print "Progress: #{message} "
      print "[post: #{@app_host}] "
      response = HTTP.headers(content_type: 'application/json')
                     .post(
                       @app_host,
                       body: message_body(message)
                     )
      puts "(#{response.status})"
    rescue HTTP::ConnectionError
      puts '(Faye server not found - progress not sent)'
    end

    private

    # Schema of message to be published
    def message_body(message)
      {
        channel: "/#{@channel_id}",
        data: {
          processing: message
        }
      }.to_json
    end
  end
end
