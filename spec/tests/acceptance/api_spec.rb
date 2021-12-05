# frozen_string_literal: true

require_relative '../../helpers/database_helper'
require_relative '../../helpers/vcr_helper'
require_relative '../../spec_helper'
require 'rack/test'

def app
  Skiller::App
end

valid_request = 'frontend'
no_result_request = 'asdf'
invalid_request = '000'

describe 'Test API routes' do
  include Rack::Test::Methods

  Skiller::VcrHelper.setup_vcr

  before do
    Skiller::VcrHelper.configure_integration
    Skiller::DatabaseHelper.wipe_database
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

  describe 'Analyze skills from job' do
    it 'should be able to return result' do
      get "api/v1/jobs?query=#{valid_request}"
      _(last_response.status).must_equal 200

      result = JSON.parse last_response.body
      _(result['query']).must_equal valid_request
      _(result['jobs']).must_be_kind_of Array
      _(result['skills']).must_be_kind_of Array
      _(result['jobs'].length).must_equal 100
      _(result['salary_dist'].keys).must_include 'maximum'
      _(result['salary_dist'].keys).must_include 'minimum'
      _(result['salary_dist'].keys).must_include 'currency'
      _(result['links']).must_be_kind_of Array

      job = result['jobs'].first
      _(job.keys).must_include 'job_id'
      _(job.keys).must_include 'title'
      _(job.keys).must_include 'description'
      _(job.keys).must_include 'location'
      _(job.keys).must_include 'salary'
      _(job.keys).must_include 'url'
      _(job.keys).must_include 'is_full'

      ten_jobs = result['jobs'][0..10]
      selected = ten_jobs.reject { |a_job| a_job['is_full'] == true }
      _(selected).must_be_empty

      skill = result['skills'].first
      _(skill.keys).must_include 'name'
      _(skill.keys).must_include 'salary'

      salary = skill['salary']
      _(salary.keys).must_include 'year_max'
      _(salary.keys).must_include 'year_min'
      _(salary.keys).must_include 'currency'
    end

    it 'should be able to respond to valid but no result query' do
      get "api/v1/jobs?query=#{no_result_request}"
      _(last_response.status).must_equal 422

      result = JSON.parse last_response.body
      _(result['status']).must_equal 'cannot_process'
      _(result['message']).must_include "No job found with query #{no_result_request}"
    end

    it 'should be able to return invalid query' do
      get "api/v1/jobs?query=#{invalid_request}"
      _(last_response.status).must_equal 422

      result = JSON.parse last_response.body
      _(result['status']).must_equal 'cannot_process'
      _(result['message']).must_include 'Invalid query'
    end
  end
end

# describe 'Test service objects' do
#   it 'Test AnalyzeSkills' do
#     params = {
#       "query" => valid_request
#     }
#     query_request = Skiller::Request::Query.new(params).call
#     result = Skiller::Service::AnalyzeSkills.new.call(query_request)

#     _(result.success?).must_equal true
#   end
# end
