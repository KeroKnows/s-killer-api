# frozen_string_literal: true

require 'shoryuken'
require 'yaml'

require_relative '../init'

require_relative 'reporter'
require_relative 'extract_monitor'

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
      job = SkillExtractor::JobReporter.new(job_json, SkillExtractor::Worker.config)

      # First time reporting progress
      starting_percent = SkillExtractor::ExtractMonitor.starting_percent
      job.report(starting_percent)

      # Keep reporting progress


      # Last time reporting progress

      # ======
      # request = Request.new(job_json)
      # job = request.job
      # return if job.is_analyzed # Move this to reporter

      # result = extract_skill(job)

      # result = extract_skill(job.extract_request)
      # write_skills_to_db(job, result)
      # update_job(job.extract_request)

      
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
    def write_skills_to_db(request, result)
      skills = result.map do |skill|
        Skiller::Entity::Skill.new(
          id: nil,
          name: skill,
          job_db_id: request.job_id,
          salary: request.salary
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
    class Request
      def initialize(job)
        @job = Skiller::Representer::Job.new(OpenStruct.new).from_json(job)
        @salary = @job.salary
      end

      attr_reader :job

      def job_id
        @job.db_id
      end

      # Transform OpenStruct to hash
      #  [ TODO ] should not use Value here
      def salary
        Skiller::Value::Salary.new(
          year_min: @salary.year_min,
          year_max: @salary.year_max,
          currency: @salary.currency
        )
      end
    end
  end
end
