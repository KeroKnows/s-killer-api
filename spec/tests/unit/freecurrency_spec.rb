# frozen_string_literal: true

require 'date'

require_relative '../../helpers/vcr_helper'

describe 'Test FreeCurrency library' do
  Skiller::VcrHelper.setup_vcr

  before do
    Skiller::VcrHelper.configure_currency
  end

  after do
    Skiller::VcrHelper.eject_vcr
  end

  describe 'HTTP communication of freecurrency API' do
    it 'HAPPY: should fetch with correct currency' do
      result = Skiller::FreeCurrency::Api.new(FREECURRENCY_API_KEY).request_rates(TEST_SRC_CURRENCY)
      _(result).wont_be_empty
    end

    it 'SAD: should raise exception on invalid api key' do
      _(proc do
        Skiller::FreeCurrency::Api.new('INVALID API KEY').request_rates(TEST_SRC_CURRENCY)
      end).must_raise Skiller::FreeCurrency::Errors::InvalidApiKey
    end

    it 'SAD: should raise exception on invalid currency' do
      _(proc do
        Skiller::FreeCurrency::Api.new(FREECURRENCY_API_KEY).request_rates('INVALID CURRENCY')
      end).must_raise Skiller::FreeCurrency::Errors::InvalidCurrency
    end
  end

  describe 'Cache functionality of freecurrency API' do
    it 'HAPPY: should generate cached result' do
      Skiller::FreeCurrency::Api.new(FREECURRENCY_API_KEY).exchange_rates(TEST_SRC_CURRENCY)
      _(File.exist?(Skiller::FreeCurrency::Api::CACHE_FILE)).must_equal true
    end

    it 'HAPPY: should be able to update expired cache' do
      # generate expired cache
      expired_cache = {
        'date' => (Date.today - Skiller::FreeCurrency::Api::EXPIRE_TIME).to_s,
        'data' => {}
      }
      File.write(Skiller::FreeCurrency::Api::CACHE_FILE, expired_cache.to_yaml, mode: 'w')

      # request data
      Skiller::FreeCurrency::Api.new(FREECURRENCY_API_KEY).exchange_rates(TEST_SRC_CURRENCY)

      # check if updated
      date = YAML.safe_load(File.read(Skiller::FreeCurrency::Api::CACHE_FILE))['date']
      _(Date.parse(date).to_s).must_equal Date.today.to_s
    end

    it 'HAPPY: should request result from API if no cache presents' do
      cached_file = Skiller::FreeCurrency::Api::CACHE_FILE
      File.delete(cached_file) if File.exist? cached_file

      Skiller::FreeCurrency::Api.new(FREECURRENCY_API_KEY).exchange_rates(TEST_SRC_CURRENCY)
      _(File.exist?(Skiller::FreeCurrency::Api::CACHE_FILE)).must_equal true
    end
  end

  describe 'Exchange rate between two currencies' do
    it 'HAPPY: should fetch with correct exchange rate' do
      result = Skiller::FreeCurrency::ExchangeRateMapper.new(CONFIG).exchange_rate(TEST_SRC_CURRENCY, TEST_TGT_CURRENCY)
      _(result).must_be_instance_of Float
    end

    it 'HAPPY: should be able to take care of the special case that source == target' do
      result = Skiller::FreeCurrency::ExchangeRateMapper.new(CONFIG).exchange_rate(TEST_SRC_CURRENCY, TEST_SRC_CURRENCY)
      _(result).must_be_instance_of Float
    end

    it 'SAD: should raise exception on invalid target currency' do
      _(proc do
        Skiller::FreeCurrency::ExchangeRateMapper.new(CONFIG).exchange_rate(TEST_SRC_CURRENCY, 'INVALID TGT CURRENCY')
      end).must_raise RuntimeError
    end
  end
end
