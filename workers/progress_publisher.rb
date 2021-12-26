# frozen_string_literal: true

require 'http'

module SkillExtractor
  # Publishes current processing job_title to Faye endpoint
  class ProgressPublisher
    def initialize(config, channel_id)
      @config = config
      @channel_id = channel_id
      @api_host = "#{@config.APP_HOST}/faye".freeze
    end

    # Post a progress to Faye endpoint
    def publish(message)
      puts " [ POST #{@api_host} ] Progress: #{message}"
      HTTP.headers(content_type: 'application/json')
          .post(
            @api_host,
            body: message_body(message)
          )
    rescue HTTP::ConnectionError
      puts ' [ WARN ] Faye server not found - progress not sent'
    end

    private

    # Schema of message to be published
    def message_body(message)
      {
        channel: "/#{@channel_id}",
        data: message
      }.to_json
    end
  end
end
