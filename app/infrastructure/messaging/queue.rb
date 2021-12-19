# frozen_string_literal: true

require 'aws-sdk-sqs'

module Skiller
  module Messaging
    # Queue wrapper for AWS SQS
    # Requires: AWS credentials loaded (in config file)
    class Queue
      IDLE_TIMEOUT = 5 # sec

      def initialize(queue_url, config)
        @queue_url = queue_url
        @config = config
        @queue = prepare_queue
      end

      def send(message)
        @queue.send_message(message_body: message)
      end

      def poll
        poller = Aws::SQS::QueuePoller.new(@queue_url)
        poller.poll(idle_timeout: IDLE_TIMEOUT) do |msg|
          yield msg.body if block_given?
        end
      end

      private

      def prepare_queue
        sqs = Aws::SQS::Client.new(
          access_key_id: @config.AWS_ACCESS_KEY_ID,
          secret_access_key: @config.AWS_SECRET_ACCESS_KEY,
          region: @config.AWS_REGION
        )
        Aws::SQS::Queue.new(url: @queue_url, client: sqs)
      end
    end
  end
end
