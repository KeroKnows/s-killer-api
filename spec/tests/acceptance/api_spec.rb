# frozen_string_literal: true

require_relative '../../helpers/database_helper.rb'
require_relative '../../helpers/vcr_helper.rb'
require_relative '../../spec_helper'
require 'rack/test'

def app
  Skiller::App
end

describe 'Test API routes' do
  include Rack::Test::Methods
  
  Skiller::VcrHelper.setup_vcr
  # Skiller::DatabaseHelper.setup_database_cleaner

  before do
    Skiller::VcrHelper.configure_reed(GATEWAY_DATABASE_CASSETTE_FILE)
    Skiller::DatabaseHelper.wipe_database
    # job_mapper = Skiller::Reed::JobMapper.new(CONFIG)
    # @partial_jobs = job_mapper.job_list(TEST_KEYWORD)
    # @first_10_jobs = @partial_jobs[0...10].map { |pg| job_mapper.job(pg.job_id) }
  end

  after do
    Skiller::VcrHelper.eject_vcr
  end

  describe 'Root route' do
    it 'should successfully return root information' do
      get '/'
      _(last_response.status).must_equal 200

      body = JSON.parse(last_response.body)
      _(body['status']).must_equal 'ok'
      _(body['message']).must_include 'api/v1'
    end
  end

  describe 'Query result' do
    it 'should be able to show query' do
      get "api/v1/jobs?query=frontend"

      _(last_response.status).must_equal 200

      result = JSON.parse last_response.body
      _(result['query']).must_equal 'frontend'
    end
  end
end