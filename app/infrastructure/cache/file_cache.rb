module Skiller
  module Cache
    # Redis client utility
    class FileClient
      def initialize(file_path)
        @file_path = file_path
        @cache = load_cache
      end

      # Open a file for caching if the passed file path not existed
      # the file **must** be an YAML file
      def load_cache
        if !File.exist?(@file_path)
          # create a file containing an empty hash for file caching
          File.write(@file_path, {}.to_yaml, mode: 'w')
        end
        YAML.safe_load(File.read(@file_path))
      end

      # Return nil if the key has been expired or not existed
      def get(key)
        expire?(key) ? nil : @cache.fetch(key, nil)&.fetch('value')
      end

      def set(key, value, expire_time)
        @cache[key] = {
          'value' => value,
          'date' => Date.today.to_s,
          'expire_time' => expire_time
        }
        File.write(@file_path, @cache.to_yaml, mode: 'w')
      end

      def expire?(key)
        if !exist?(key)
          false
        else
          properties = @cache[key]
          (Date.today - Date.parse(properties['date'])) >= properties['expire_time']
        end
      end

      def exist?(key)
        @cache.key?(key)
      end

      def keys
        @cache.keys
      end

      def wipe
        keys.each { |key| @cache.delete(key) }
        File.write(@file_path, @cache.to_yaml, mode: 'w')
      end
    end
  end
end
