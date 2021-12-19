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
  shoryuken_options queue: config.CLONE_QUEUE_URL, auto_delete: true

  PYTHON = 'python3' # may need to change this to `python`, depending on your system
  SCRIPT = File.join(File.dirname(__FILE__), 'extract.py')

  # extract skill and store in database
  def perform(_sqs_msg, jobs)
    random_seed = rand(10_000)
    jobs = JSON.parse jobs
    jobs.each do |job|
      job = Skiller::Representer::Job.new(OpenStruct.new).from_json(job.to_json)
      tmp_file = File.join(File.dirname(__FILE__), ".extractor.#{random_seed}.tmp")
      File.write(tmp_file, job.description, mode: 'w')
      script_result = `#{PYTHON} #{SCRIPT} "#{tmp_file}"`
      File.delete(tmp_file)
      write_to_db(job, script_result)
    end
  end

  # store the results to database
  #  [ TODO ] improve the structure (sorry for the mess here)
  def write_to_db(job, result)
    skills = YAML.safe_load(result)
    salary = Skiller::Value::Salary.new({
      year_min: job.salary.year_min,
      year_max: job.salary.year_max,
      currency: job.salary.currency
    })
    skills = skills.map do |skill|
      Skiller::Entity::Skill.new(
        id: nil,
        name: skill,
        job_db_id: job.db_id,
        salary: salary
      )
    end
    Skiller::Repository::JobsSkills.find_or_create(skills)
  end
end
