# frozen_string_literal: true

# Specify we are in test environment as the first thing in our spec setup
ENV['RACK_ENV'] = 'test'

require 'simplecov'
SimpleCov.start

require 'cgi'
require 'minitest/autorun'
require 'minitest/rg'
require 'vcr'
require 'webmock'
require 'yaml'
require 'http'

require_relative '../init'

Figaro.application = Figaro::Application.new(
  environment: ENV,
  path: File.expand_path('config/secrets.yml')
)
Figaro.load
CONFIG = Figaro.env
REED_TOKEN = CONFIG.REED_TOKEN
CREDENTIALS = Base64.strict_encode64("#{REED_TOKEN}:")

FREECURRENCY_API_KEY = CONFIG.FREECURRENCY_API_KEY

# TESTING
TEST_KEYWORD = 'backend'
INVALID_KEYWORD = '0000'
EMPTY_KEYWORD = ''
EMPTY_RESULT_KEYWORD = 'asdf'
TEST_SRC_CURRENCY = 'TWD'
TEST_TGT_CURRENCY = 'USD'
TEST_CACHE_FILE = 'tmp_cache.yml'
TEST_CACHE_KEY = 'foo'
TEST_CACHE_VALUE = 'boo'
TEST_EXPIRE_TIME = 1
