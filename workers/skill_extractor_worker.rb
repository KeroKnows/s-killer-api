# frozen_string_literal: true

require 'shoryuken'
require 'yaml'

require_relative '../init'

require_relative 'reporter'

module SkillExtractor
  # Worker to analyze skills in parallel
  class Worker
    # Environment variables setup
    Figaro.application = Figaro::Application.new(
      environment: ENV['RACK_ENV'] || 'development',
      path: File.expand_path('config/secrets.yml')
    )
    Figaro.load

    def self.config() = Figaro.env

    include Shoryuken::Worker
    shoryuken_options queue: config.EXTRACTOR_QUEUE_URL, auto_delete: true

    PYTHON = 'python3' # may need to change this to `python`, depending on your system
    SCRIPT = File.join(File.dirname(__FILE__), 'extract.py')

    # extract skill and store in database
    # :reek:TooManyStatements
    def perform(_sqs_msg, job_json)
      work = SkillExtractor::JobReporter.new(job_json, SkillExtractor::Worker.config)

      # Reporting progress, testing for channel ID
      work.report(10)  # channel ID is not responding exactly?

      extract_request = Skiller::Representer::ExtractRequest.new(OpenStruct.new).from_json(job_json)

      job = extract_request.job
      return if job.is_analyzed # Move this to reporter

      db_id = job.db_id  # to database
      salary = Skiller::Value::Salary.new(  # to database
        year_min: job.salary.year_min,
        year_max: job.salary.year_max,
        currency: job.salary.currency
      )
      
      result = extract_skill(job)
      write_skills_to_db(result, db_id, salary)
      update_job(job)

      work.report(100)
    end

    # run the extractor script
    def extract_skill(job)
      tmp_file = File.join(File.dirname(__FILE__), ".extractor.#{rand(10_000)}.tmp")
      File.write(tmp_file, job.description, mode: 'w')
      script_result = `#{PYTHON} #{SCRIPT} "#{tmp_file}"`
      File.delete(tmp_file)
      YAML.safe_load script_result
    end

    # store the results to database
    #  [ TODO ] should not use Entity here
    # :reek:UtilityFunction because it is a utility function
    # def write_skills_to_db(request, result)
    def write_skills_to_db(result, job_id, salary)
      skills = result.map do |skill|
        Skiller::Entity::Skill.new(
          id: nil,
          name: skill,
          # job_db_id: request.job_id,
          # salary: request.salary
          job_db_id: job_id,
          salary: salary
        )
      end
      Skiller::Repository::JobsSkills.find_or_create(skills)
    end

    # :reek:UtilityFunction because it is a utility function
    def update_job(job)
      job.is_analyzed = true
      Skiller::Repository::Jobs.update(job)
    end

    # An utility entity to process request data
    # class Request
    #   def initialize(job)
    #     @job = Skiller::Representer::Job.new(OpenStruct.new).from_json(job)
    #     @salary = @job.salary
    #   end

    #   attr_reader :job

    #   def job_id
    #     @job.db_id
    #   end

    #   # Transform OpenStruct to hash
    #   #  [ TODO ] should not use Value here
    #   def salary
    #     Skiller::Value::Salary.new(
    #       year_min: @salary.year_min,
    #       year_max: @salary.year_max,
    #       currency: @salary.currency
    #     )
    #   end
    # end
  end
end
