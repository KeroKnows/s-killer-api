# frozen_string_literal: true

require_relative '../../helpers/database_helper'
require_relative '../../helpers/vcr_helper'
require_relative '../../spec_helper'
require 'rack/test'

def app
  Skiller::App
end

describe 'Test API routes' do
  include Rack::Test::Methods

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
    it 'should be able to ask users wait for result' do
      # GIVEN: db is wiped so the keyword must not exist
      Skiller::DatabaseHelper.wipe_database

      # WHEN: ask for this keyword
      get "#{JOB_ROUTE}?query=#{TEST_KEYWORD}"

      # THEN: ask user to wait
      _(last_response.status).must_equal 202
    end

    it 'should be able to return result' do
      # GIVEN: call the API to ensure data exists
      get "#{JOB_ROUTE}?query=#{TEST_KEYWORD}"
      if last_response.status == 202
        sleep 30 # wait for workers to process
      end

      # WHEN: ask for this keyword
      get "#{JOB_ROUTE}?query=#{TEST_KEYWORD}"

      # THEN: must return the result
      _(last_response.status).must_equal 200

      result = JSON.parse last_response.body
      _(result['query']).must_equal TEST_KEYWORD
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

      skill = result['skills'].first
      _(skill.keys).must_include 'name'
      _(skill.keys).must_include 'salary'

      # not testing salary keys because it may be nil
    end

    it 'should be able to respond to a valid but no result query' do
      get "/api/v1/jobs?query=#{EMPTY_RESULT_KEYWORD}"
      _(last_response.status).must_equal 422

      result = JSON.parse last_response.body
      _(result['status']).must_equal 'cannot_process'
      _(result['message'].downcase).must_include 'no job found'
    end

    it 'should be able to return invalid query' do
      get "/api/v1/jobs?query=#{INVALID_KEYWORD}"
      _(last_response.status).must_equal 422

      result = JSON.parse last_response.body
      _(result['status']).must_equal 'cannot_process'
      _(result['message'].downcase).must_include 'invalid'
    end
  end

  describe 'Request Job Detail' do
    it 'HAPPY: should respond the detail result' do
      # GIVEN: ensure jobs exist in database and get a job id
      get "#{JOB_ROUTE}?query=#{TEST_KEYWORD}"
      if last_response.status == 202
        sleep 30 # wait for workers to process
      end

      vailid_job_id = Skiller::Database::JobOrm.select(:db_id).where(is_full: true).first.db_id

      # WHEN: request for that job
      get "#{DETAIL_ROUTE}/#{vailid_job_id}"

      # THEN: the information should be properly returned
      _(last_response.status).must_equal 200

      result = JSON.parse last_response.body
      _(result).must_include 'id'
      _(result).must_include 'title'
      _(result).must_include 'description'
      _(result).must_include 'location'
      _(result).must_include 'salary'
      _(result).must_include 'url'
    end

    it 'BAD: should respond to a non-existing job id' do
      # GIVEN: an already erased job id
      first_job_id = Skiller::Database::JobOrm.select(:db_id).where(is_full: true).first.db_id
      erased_job_id = first_job_id - 1

      # WHEN: request for that job
      get "#{DETAIL_ROUTE}/#{erased_job_id}"

      # THEN: should tell user that the job doesn't exist
      _(last_response.status).must_equal 404
      result = JSON.parse last_response.body
      _(result['message'].downcase).must_include 'not found'
    end

    it 'SAD: should respond to a job without full description' do
      # GIVEN: a partial job
      get "#{JOB_ROUTE}?query=#{TEST_KEYWORD}"
      partial_job_id = Skiller::Database::JobOrm.select(:db_id).where(is_full: false).first.db_id

      # WHEN: query for that job
      get "#{DETAIL_ROUTE}/#{partial_job_id}"

      # THEN: should tell user the job is not available
      _(last_response.status).must_equal 422
      result = JSON.parse last_response.body
      _(result['message']).must_include 'full info'
    end
  end
end
