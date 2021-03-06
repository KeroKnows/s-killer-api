# frozen_string_literal: true

require 'redis'

module Skiller
  module Cache
    # Redis client utility
    # :reek:ClassVariable
    class RedisClient
      # rubocop:disable Style/ClassVars
      @@redis = nil
      attr_reader :redis

      def initialize(redis_url)
        @@redis ||= Redis.new(url: redis_url)
        @redis = @@redis
      end

      # Return nil if the key has been expired or not existed
      def get(key)
        if expire?(key) || !exist?(key)
          nil
        else
          JSON.parse(@redis.get(key)).fetch('value')
        end
      end

      def set(key, value, expire_time)
        data = {
          'value' => value,
          'date' => Date.today.to_s,
          'expire_time' => expire_time
        }
        @redis.set(key, data.to_json)
      end

      def expire?(key)
        if exist?(key)
          properties = JSON.parse(@redis.get(key))
          (Date.today - Date.parse(properties['date'])) >= properties['expire_time']
        else
          false
        end
      end

      def exist?(key)
        @redis.exists?(key)
      end

      def keys
        @redis.keys
      end

      def wipe
        keys.each { |key| @redis.del(key) }
      end
      # rubocop:enable Style/ClassVars
    end
  end
end
