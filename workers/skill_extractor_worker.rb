# frozen_string_literal: true

require_relative '../init'
require 'shoryuken'

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

  # extract skill and store in database
  def extract_and_store(_sqs_msg, jobs)
    skill_list = jobs.map do |job|
      if Repository::JobsSkills.job_exist?(job)
        Repository::JobsSkills.find_skills_by_job_id(job.db_id)
      else
        skills = Skiller::Skill::SkillMapper.new(job).skills
        Repository::JobsSkills.find_or_create(skills)
      end
    end
    skill_list.reduce(:+)
  end
end
