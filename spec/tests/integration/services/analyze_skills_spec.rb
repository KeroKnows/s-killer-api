# frozen_string_literal: true

require_relative '../../../helpers/vcr_helper'
require_relative '../../../helpers/database_helper'
require_relative '../../../spec_helper'

def cannot_process?(result)
  result.failure? and result.failure.status == :cannot_process
end


describe 'Integration Test for AnalyzeSkills Service' do
  Skiller::VcrHelper.setup_vcr

  before do
    Skiller::VcrHelper.configure_integration
  end

  after do
    Skiller::VcrHelper.eject_vcr
  end

  describe 'Data validation' do
    it 'BAD: should fail empty query' do
      # GIVEN: an empty query
      query_form = Skiller::Request::Query.new.call({ 'query' => EMPTY_KEYWORD })

      # WHEN: the service is called
      jobskill = Skiller::Service::AnalyzeSkills.new.call(query_form)

      # THEN: the service should fail
      _(cannot_process?(jobskill)).must_equal true
      _(jobskill.failure[:message].downcase).must_include 'invalid'
    end

    it 'SAD: should fail with invalid request' do
      # GIVEN: an invalid query
      query_form = Skiller::Request::Query.new.call({ 'query' => INVALID_KEYWORD })

      # WHEN: the service is called
      jobskill = Skiller::Service::AnalyzeSkills.new.call(query_form)

      # THEN: the service should fail
      _(cannot_process?(jobskill)).must_equal true
      _(jobskill.failure[:message].downcase).must_include 'invalid'
    end
  end

  describe 'Retrieve and store jobs' do
    before do
      Skiller::DatabaseHelper.wipe_database
    end

    it 'HAPPY: should search query and generate corresponding entities' do
      skip 'next week'

      # GIVEN: a keyword that hasn't been searched
      query_form = Skiller::Request::Query.new.call({ 'query' => TEST_KEYWORD })

      # WHEN: the service is called with the form object
      jobskill = Skiller::Service::AnalyzeSkills.new.call(query_form)

      # THEN: the service should succeed...
      _(jobskill.success?).must_equal true

      # ...and the jobs should have correct details
      rebuilt_jobs = jobskill.value!.message[:jobs]
      job_mapper = Skiller::Reed::JobMapper.new(CONFIG)
      ori_jobs = rebuilt_jobs.map { |job| job_mapper.job(job.job_id) }

      ori_jobs.zip(rebuilt_jobs).map do |orig, rebuilt|
        _(rebuilt.job_id).must_equal orig.job_id
        _(rebuilt.title).must_equal orig.title
        _(rebuilt.location).must_equal orig.location
      end
      # Did not test the description, because not all entities have full description
      # Did not test salary and url, because they may be nil
    end

    it 'HAPPY: should collect jobs from database' do
      skip 'next week'

      # GIVEN: a keyword that has been searched
      query_form = Skiller::Request::Query.new.call({ 'query' => TEST_KEYWORD })
      db_jobs = Skiller::Service::AnalyzeSkills.new.call(query_form).value!.message[:jobs]

      # WHEN: the service is called with the form object
      jobskill = Skiller::Service::AnalyzeSkills.new.call(query_form)

      # THEN: the service should succeed...
      _(jobskill.success?).must_equal true

      # ...and rebuilt the same entities as those from the database
      rebuilt_jobs = jobskill.value!.message[:jobs]

      db_jobs.zip(rebuilt_jobs).map do |db, rebuilt|
        _(rebuilt.job_id).must_equal db.job_id
        _(rebuilt.title).must_equal db.title
        _(rebuilt.description).must_equal db.description
        _(rebuilt.location).must_equal db.location
      end
      # Did not test salary and url, because they may be nil
    end

    it 'HAPPY: should calculate salary distribution from a job list' do
      skip 'next week'

      # GIVEN: a keyword
      query_form = Skiller::Request::Query.new.call({ 'query' => TEST_KEYWORD })

      # WHEN: the service is called
      jobskill = Skiller::Service::AnalyzeSkills.new.call(query_form)

      # THEN: the service should succeed...
      _(jobskill.success?).must_equal true
      jobskill = jobskill.value!.message

      # ...and culculate the salary distribution
      ## get correct salary distribution
      job_mapper = Skiller::Reed::JobMapper.new(CONFIG)
      jobs = jobskill[:jobs][..Skiller::Service::AnalyzeSkills::ANALYZE_LEN].map { |job| job_mapper.job(job.job_id) }
      salaries = jobs.map(&:salary)
      ori_salary = Skiller::Entity::SalaryDistribution.new(salaries)

      ## get rebuilt salary distribution
      rebuilt_salary = jobskill[:salary_dist]

      ## validate
      _(rebuilt_salary.maximum).must_equal ori_salary.maximum
      _(rebuilt_salary.minimum).must_equal ori_salary.minimum
      _(rebuilt_salary.currency).must_equal ori_salary.currency
    end
  end

  describe 'Extract and store skills' do
    before do
      Skiller::DatabaseHelper.wipe_database
    end

    it 'HAPPY: should analyze skills and store result into database' do
      skip 'next week'

      # GIVEN: a keyword that has not been searched
      query_form = Skiller::Request::Query.new.call({ 'query' => TEST_KEYWORD })

      # WHEN: the service is called
      jobskill = Skiller::Service::AnalyzeSkills.new.call(query_form)

      # THEN: the service whould succeed...
      _(jobskill.success?).must_equal true
      jobskill = jobskill.value!.message

      # ...with correct skills extracted
      ## get correct skills
      job_mapper = Skiller::Reed::JobMapper.new(CONFIG)
      jobs = jobskill[:jobs][..Skiller::Service::AnalyzeSkills::ANALYZE_LEN].map { |job| job_mapper.job(job.job_id) }
      skills_list = jobs.map { |job| Skiller::Skill::SkillMapper.new(job).skills }
      ori_skills = skills_list.reduce(:+).sort_by(&:name)

      ## get rebuilt skills
      rebuilt_skills = jobskill[:skills].sort_by(&:name)

      ## validate
      ori_skills.zip(rebuilt_skills).each do |ori, rebuilt|
        _(rebuilt.name).must_equal ori.name
      end
      # Did not test id and salary, because they may be nil
    end

    it 'HAPPY: should collect skills from database' do
      skip 'next week'

      # GIVEN: a keyword that has been searched
      query_form = Skiller::Request::Query.new.call({ 'query' => TEST_KEYWORD })
      db_skills = Skiller::Service::AnalyzeSkills.new.call(query_form).value!.message[:skills]
      db_skills = db_skills.sort_by(&:name)

      # WHEN: the service is called
      jobskill = Skiller::Service::AnalyzeSkills.new.call(query_form)

      # THEN: the service whould succeed...
      _(jobskill.success?).must_equal true
      jobskill = jobskill.value!.message

      # ...with correct skills rebuilt
      rebuilt_skills = jobskill[:skills].sort_by(&:name)
      db_skills.zip(rebuilt_skills).each do |db, rebuilt|
        _(rebuilt.name).must_equal db.name
      end
      # Did not test id and salary, because they may be nil
    end
  end
end
