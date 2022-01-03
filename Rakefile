# frozen_string_literal: true

require 'rake/testtask'

CODE = 'config/ app/'

task :default do
  puts `rake -T`
end

desc 'start the app with file chages watched'
task :dev do
  sh "rerun -c 'bundle exec puma config.ru -p 4001' " \
     "--ignore 'workers/*' --ignore 'coverage/*' --ignore 'spec/*' --ignore '*.slim'"
end

desc 'run all quality checks'
task quality: 'quality:all'

desc 'Run application console (irb)'
task :console do
  sh 'pry -r ./init.rb'
end

desc 'Run all spec at once'
task :spec do
  sh 'RACK_ENV=test bundle exec rake spec_all'
end

desc 'Run acceptance spec'
task :spec_accept do
  sh 'RACK_ENV=test buncle exec rake spec_accept_all'
end

desc 'Run all tests at once'
Rake::TestTask.new(:spec_all) do |t|
  t.pattern = 'spec/tests/{integration,unit}/**/*_spec.rb'
  t.warning = false
end

desc 'Run all acceptance tests at once'
Rake::TestTask.new(:spec_accept_all) do |t|
  t.pattern = 'spec/tests/acceptance/*_spec.rb'
  t.warning = false
end

namespace :db do
  task :config do
    require 'sequel'
    require_relative 'config/environment' # load config info
    require_relative 'spec/helpers/database_helper'

    def app
      Skiller::App
    end
  end

  desc 'Run migrations'
  task migrate: :config do
    Sequel.extension :migration
    puts "Migrating #{app.environment} database to latest"
    Sequel::Migrator.run(app.DB, 'app/infrastructure/database/migrations')
    sh 'find app/infrastructure/database/local -print'
  end

  desc 'Wipe records from all tables'
  task wipe: :config do
    if app.environment == :production
      puts 'Do not damage production database!'
      return
    end

    require_relative 'spec/helpers/database_helper'
    Skiller::DatabaseHelper.wipe_database
  end

  desc 'Delete dev or test database file (set correct RACK_ENV)'
  task drop: :config do
    if app.environment == :production
      puts 'Do not damage production database!'
      return
    end

    FileUtils.rm(Skiller::App.config.DB_FILENAME)
    puts "Deleted #{Skiller::App.config.DB_FILENAME}"
  end
end

namespace :quality do
  task all: %i[rubocop flog reek]

  desc "flog: check #{CODE}"
  task :flog do
    sh "flog -m #{CODE}"
  end

  desc 'reek check'
  task :reek do
    sh 'reek'
  end

  desc 'rubocop check'
  task :rubocop do
    sh 'rubocop'
  end
end

namespace :vcr do
  desc 'delete all cassettes'
  task :clean do
    sh 'rm spec/fixtures/cassettes/*.yml' do |ok, _|
      puts(ok ? 'All cassettes deleted' : 'No cassette is found')
    end
  end
end

namespace :queues do
  task :config do
    require 'aws-sdk-sqs'
    require_relative 'config/environment' # load config info
    @api = Skiller::App

    @sqs = Aws::SQS::Client.new(
      access_key_id: @api.config.AWS_ACCESS_KEY_ID,
      secret_access_key: @api.config.AWS_SECRET_ACCESS_KEY,
      region: @api.config.AWS_REGION
    )
  end

  desc 'Create SQS queue for worker'
  task create: :config do
    puts "Environment: #{@api.environment}"
    @sqs.create_queue(queue_name: @api.config.EXTRACTOR_QUEUE)

    q_url = @sqs.get_queue_url(queue_name: @api.config.EXTRACTOR_QUEUE).queue_url
    puts 'Queue created:'
    puts "  Name: #{@api.config.EXTRACTOR_QUEUE}"
    puts "  Region: #{@api.config.AWS_REGION}"
    puts "  URL: #{q_url}"
  rescue StandardError => e
    puts "Error creating queue: #{e}"
  end

  desc 'Report status of queue for worker'
  task status: :config do
    q_url = @sqs.get_queue_url(queue_name: @api.config.EXTRACTOR_QUEUE).queue_url

    puts "Environment: #{@api.environment}"
    puts 'Queue info:'
    puts "  Name: #{@api.config.EXTRACTOR_QUEUE}"
    puts "  Region: #{@api.config.AWS_REGION}"
    puts "  URL: #{q_url}"
  rescue StandardError => e
    puts "Error finding queue: #{e}"
  end

  desc 'Purge messages in SQS queue for worker'
  task purge: :config do
    q_url = @sqs.get_queue_url(queue_name: @api.config.EXTRACTOR_QUEUE).queue_url
    @sqs.purge_queue(queue_url: q_url)
    puts "Queue #{@api.config.EXTRACTOR_QUEUE} purged"
  rescue StandardError => e
    puts "Error purging queue: #{e}"
  end
end

namespace :worker do
  namespace :run do
    desc 'Run the background cloning worker in development mode'
    task dev: :config do
      # rubocop:disable Layout/LineLength
      sh 'RACK_ENV=development bundle exec shoryuken -r ./workers/skill_extractor_worker.rb -C ./workers/shoryuken_dev.yml'
      # rubocop:enable Layout/LineLength
    end

    desc 'Run the background cloning worker in testing mode'
    task test: :config do
      sh 'RACK_ENV=test bundle exec shoryuken -r ./workers/skill_extractor_worker.rb -C ./workers/shoryuken_test.yml'
    end

    desc 'Run the background cloning worker in production mode'
    task production: :config do
      sh 'RACK_ENV=production bundle exec shoryuken -r ./workers/skill_extractor_worker.rb -C ./workers/shoryuken.yml'
    end
  end
end
