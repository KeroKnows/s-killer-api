# frozen_string_literal: true

require 'shoryuken'
require 'yaml'

require_relative '../init'

# Worker to analyze skills in parallel
class SkillExtractorWorker
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
  def perform(_sqs_msg, jobs)
    jobs = JSON.parse jobs
    jobs.each do |job|
      job = Skiller::Representer::Job.new(OpenStruct.new).from_json(job.to_json)
      result = extract_skill(job)
      write_to_db(job, result)
    end
  end

  # run the extractor script
  def extract_skill(job)
    random_seed = rand(10_000)
    tmp_file = File.join(File.dirname(__FILE__), ".extractor.#{random_seed}.tmp")
    File.write(tmp_file, job.description, mode: 'w')
    script_result = `#{PYTHON} #{SCRIPT} "#{tmp_file}"`
    File.delete(tmp_file)
    YAML.safe_load script_result
  end

  # store the results to database
  #  [ TODO ] should not use Entity here (sorry for the mess here)
  def write_to_db(job, result)
    salary = prepare_salary(job.salary)
    skills = result.map do |skill|
      Skiller::Entity::Skill.new(
        id: nil,
        name: skill,
        job_db_id: job.db_id,
        salary: salary
      )
    end
    Skiller::Repository::JobsSkills.find_or_create(skills)
  end

  # Transform OpenStruct to hash
  #  [ TODO ] should not use Value here
  def prepare_salary(salary)
    Skiller::Value::Salary.new(
      year_min: salary.year_min,
      year_max: salary.year_max,
      currency: salary.currency
    )
  end
end
