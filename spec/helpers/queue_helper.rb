# frozen_string_literal: true

require_relative '../../config/init'

module Skiller
  # provide spec utility functions of queue
  module QueueHelper
    def self.wipe_queue
      config = Skiller::App.config
      queue = Skiller::Messaging::Queue.new(config.EXTRACTOR_QUEUE_URL, config)
      queue.wipe
    end
  end
end
