# frozen_string_literal: true

require_relative '../../../helpers/vcr_helper'
require_relative '../../../helpers/database_helper'
require_relative '../../../spec_helper'

describe 'Integration Test for RequestDetail Service' do
  Skiller::VcrHelper.setup_vcr

  before do
    Skiller::VcrHelper.configure_integration
  end

  after do
    Skiller::VcrHelper.eject_vcr
  end

  it 'SAD: should fail invalid db_id' do
    # GIVEN: an invalid job id
    Skiller::DatabaseHelper.wipe_database
    invalid_job_id = 1000 # this should be invalid because database has been wiped

    # WHEN: the service is called
    job_detail = Skiller::Service::RequestDetail.new.call(invalid_job_id)

    # THEN: service should fail with warning message
    _(job_detail.failure?).must_equal true
    _(job_detail.failure.message).wont_be_empty
  end

  it 'SAD: should fail with partial job data' do
    # GIVEN: a partial job stored db
    Skiller::DatabaseHelper.wipe_database
    salary = Skiller::Value::Salary.new(year_min: nil, year_max: nil, currency: nil)
    job = Skiller::Entity::Job.new(db_id: nil,
                                   job_id: 1,
                                   title: 'JOB TITLE',
                                   description: '<h1>JOB TITLE</h1><p>description</p>',
                                   location: 'LOCATION',
                                   salary: salary,
                                   url: nil,
                                   is_full: false,
                                   is_analyzed: false)
    db_job = Skiller::Repository::Jobs.find_or_create(job)

    # WHEN: the service is called
    job_detail = Skiller::Service::RequestDetail.new.call(db_job.db_id)

    # THEN: service should fail with warning message
    _(job_detail.failure?).must_equal true
    _(job_detail.failure.message).wont_be_empty
  end

  it 'HAPPY: should search from job_id' do
    # GIVEN: a healthy job_id
    Skiller::DatabaseHelper.wipe_database
    job_id = 1
    salary = Skiller::Value::Salary.new(year_min: nil, year_max: nil, currency: nil)
    job = Skiller::Entity::Job.new(db_id: job_id,
                                   job_id: 1,
                                   title: 'JOB TITLE',
                                   description: '<h1>JOB TITLE</h1><p>description</p>',
                                   location: 'LOCATION',
                                   salary: salary,
                                   url: nil,
                                   is_full: true,
                                   is_analyzed: false)
    db_job = Skiller::Repository::Jobs.find_or_create(job)

    # WHEN: the service is called
    job_detail = Skiller::Service::RequestDetail.new.call(db_job.db_id)

    # THEN: service should succeed with job detail returned
    _(job_detail.success?).must_equal true
  end
end
