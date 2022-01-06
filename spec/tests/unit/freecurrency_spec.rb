# frozen_string_literal: true

require 'date'

require_relative '../../spec_helper'
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

    it 'SAD: should raise exception on invalid currency' do
      _(proc do
        Skiller::FreeCurrency::Api.new(FREECURRENCY_API_KEY).request_rates('INVALID CURRENCY')
      end).must_raise Skiller::FreeCurrency::Errors::InvalidCurrency
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
