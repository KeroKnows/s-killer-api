# frozen_string_literal: true

require_relative '../../helpers/vcr_helper'

describe 'Test Reed library' do
  Skiller::VcrHelper.setup_vcr

  before do
    Skiller::VcrHelper.configure_reed
  end

  after do
    Skiller::VcrHelper.eject_vcr
  end

  describe 'HTTP communication of Reed Search API' do
    it 'HAPPY: should fetch with correct keyword' do
      result = Skiller::Reed::Api.new(REED_TOKEN).search(TEST_KEYWORD)
      _(result).wont_be_empty
    end

    it 'SAD: should raise exception on invalid token' do
      _(proc do
        Skiller::Reed::Api.new('INVALID TOKEN').search(TEST_KEYWORD)
      end).must_raise Skiller::Reed::Errors::InvalidToken
    end
  end

  it 'HAPPY: job list should be PartialJob' do
    jobs = Skiller::Reed::JobMapper.new(CONFIG, Skiller::Reed::Api).job_list(TEST_KEYWORD)
    jobs.each { |job| _(job.is_full).must_be_same_as false }
  end

  describe 'HTTP communication of Reed Details API' do
    it 'HAPPY: should fetch details with correct job id' do
      jobs = Skiller::Reed::JobMapper.new(CONFIG, Skiller::Reed::Api).job_list(TEST_KEYWORD)
      details = Skiller::Reed::Api.new(REED_TOKEN).details(jobs.first.job_id)
      _(details).wont_be_empty
    end

    it 'SAD: should raise exception on invalid job id' do
      _(proc do
        Skiller::Reed::Api.new(REED_TOKEN).details('INVALID JOB_ID')
      end).must_raise Skiller::Reed::Errors::InvalidJobId
    end
  end

  describe 'JobInfo' do
    before do
      job_mapper = Skiller::Reed::JobMapper.new(CONFIG, Skiller::Reed::Api)
      partial_jobs = job_mapper.job_list(TEST_KEYWORD)
      @partial_job = partial_jobs.first
      @job = job_mapper.job(@partial_job.job_id)
    end

    it 'HAPPY: should have job ID' do
      _(@job).must_respond_to :job_id
    end

    it 'HAPPY: should have location' do
      _(@job).must_respond_to :location
    end

    it 'HAPPY: should have title' do
      _(@job).must_respond_to :title
    end

    describe 'Salary' do
      before do
        @salary = @job.salary
      end

      it 'HAPPY: should have yearly minimum salary' do
        _(@salary).must_respond_to :year_min
      end

      it 'HAPPY: should have yearly maximum salary' do
        _(@salary).must_respond_to :year_max
      end

      it 'HAPPY: should have currency' do
        _(@salary).must_respond_to :currency
      end

      it 'HAPPY: should be able to compute yearly average salary' do
        if @salary.year_min.nil? && @salary.year_max.nil?
          assert_operator @salary.year_avg, :==, nil
        else
          assert_operator @salary.year_avg, :==, (@salary.year_min + @salary.year_max) / 2
        end
      end

      it 'HAPPY: should be able to exchange its currency' do
        new_salary = @salary.exchange_currency(TEST_TGT_CURRENCY)
        _(new_salary).must_be_instance_of Skiller::Value::Salary
      end
    end

    it 'HAPPY: should have url to the job application' do
      _(@job).must_respond_to :url
    end

    it 'HAPPY: should have `is_full`' do
      _(@job).must_respond_to :is_full
    end

    it 'HAPPY: `is_full` should be true' do
      _(@job.is_full).must_be_same_as true
    end

    it 'HAPPY: JobMapper should generate Job' do
      _(@job).must_be_instance_of Skiller::Entity::Job
    end

    it 'HAPPY: should be able to request full job info' do
      assert_operator @job.description.length, :>=, @partial_job.description.length
    end

    it 'HAPPY: should have description' do
      _(@job).must_respond_to :description
    end
  end
end
