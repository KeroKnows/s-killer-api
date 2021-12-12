# frozen_string_literal: true

require 'date'

describe 'Test Cache library' do
  describe 'Functionalities of file caching' do
    before do
      system("rm #{TEST_CACHE_FILE}") if File.exist?(TEST_CACHE_FILE)
      @cache = Skiller::Cache::FileClient.new(TEST_CACHE_FILE)
    end

    after do
      system("rm #{TEST_CACHE_FILE}")
    end

    it 'HAPPY: should generate cached file' do
      @cache.set(TEST_CACHE_KEY, TEST_CACHE_VALUE, TEST_EXPIRE_TIME)
      _(File.exist?(TEST_CACHE_FILE)).must_equal true
    end

    it 'HAPPY: should be able to check if a key existed' do
      @cache.wipe

      _(@cache.exist?(TEST_CACHE_KEY)).must_equal false
      @cache.set(TEST_CACHE_KEY, TEST_CACHE_VALUE, TEST_EXPIRE_TIME)
      _(@cache.exist?(TEST_CACHE_KEY)).must_equal true
    end

    it 'HAPPY: should be able to check if a key expired' do
      # generate expired cache
      @cache.set(TEST_CACHE_KEY, TEST_CACHE_VALUE, 0)

      _(@cache.expire?(TEST_CACHE_KEY)).must_equal true
    end

    it 'HAPPY: should get cached value' do
      @cache.set(TEST_CACHE_KEY, TEST_CACHE_VALUE, TEST_EXPIRE_TIME)
      _(@cache.get(TEST_CACHE_KEY)).must_equal TEST_CACHE_VALUE
    end
  end
end
