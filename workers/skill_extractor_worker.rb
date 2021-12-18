require_relative '../init'
require 'econfig'
require 'shoryuken'

# Worker to analyze skills in parallel
class GitCloneWorker
  # Environment variables setup
  Figaro.application = Figaro::Application.new(
    environment: ENV['RACK_ENV'] || 'development',
    path: File.expand_path('config/secrets.yml')
  )
  Figaro.load

  def self.config() = Figaro.env

  include Shoryuken::Worker
  shoryuken_options queue: config.CLONE_QUEUE_URL, auto_delete: true

  def perform(_sqs_msg, request)
    project = Skiller::Representer::Project
      .new(OpenStruct.new)
      .from_json(request)
  
    CodePraise::GitRepo.new(project).clone!
  rescue CodePraise::GitRepo::Errors::CannotOverwriteLocalGitRepo
    puts 'Clone exists -- ignoring request'
  end
end
