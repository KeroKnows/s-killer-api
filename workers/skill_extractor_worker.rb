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

      extract_request = Skiller::Representer::ExtractRequest.new(OpenStruct.new).from_json(job_json)
      job = extract_request.job

      work.report(job.title) # channel ID is not responding exactly?

      return if job.is_analyzed

      salary = get_salary_value(job.salary)

      result = extract_skill(job)
      write_skills_to_db(result, job.db_id, salary)
      update_job(job)
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

    # get salary value for database
    def get_salary_value(salary)
      Skiller::Value::Salary.new(
        year_min: salary.year_min,
        year_max: salary.year_max,
        currency: salary.currency
      )
    end
  end
end
