# frozen_string_literal: true

require 'rake/testtask'

## ------ CONFIGURATION ------ ##
CASSETTE_FOLDER = 'spec/fixtures/cassettes'
CACHE_FOLDER = '_cache/rack'
CODE = 'config/ app/'
HOST = '127.0.0.1'
DEV_PORT = '4001'
TEST_PORT = '4010'

## ------ ALIAS ------ ##
task :default do
  puts `rake -T`
end

desc 'alias to run:dev'
task dev: 'run:dev'

desc 'alias to quality:all'
task quality: 'quality:all'

desc 'alias to spec:all'
task spec: 'spec:all'

## ------ UTILITIES ------ ##
desc 'Run application console (irb)'
task :console do
  sh 'pry -r ./init.rb'
end

## ------ SERVING ------ ##
namespace :run do
  desc 'start the app with file chages watched'
  task :dev do
    sh "rerun -c 'puma config.ru -p #{DEV_PORT}' " \
       "--ignore 'workers/*' --ignore 'coverage/*' --ignore 'spec/*'"
  end

  desc 'start the app with testing environment setting'
  task :test do
    sh "bundle exec puma config.ru -p #{TEST_PORT}"
  end
end

## ------ TESTING ------ ##
namespace :run do
  namespace :spec do
    # execute all integration and unit tests at once
    Rake::TestTask.new(:all) do |t|
      t.description = '' # hide this task from `rake -T`
      t.pattern = 'spec/tests/{integration,unit}/**/*_spec.rb'
      t.warning = false
    end

    # execute all unit tests at once.
    Rake::TestTask.new(:unit) do |t|
      t.description = '' # hide this task from `rake -T`
      t.pattern = 'spec/tests/unit/**/*_spec.rb'
      t.warning = false
    end

    # execute all integration tests at once
    Rake::TestTask.new(:integration) do |t|
      t.description = '' # hide this task from `rake -T`
      t.pattern = 'spec/tests/integration/**/*_spec.rb'
      t.warning = false
    end

    # execute acceptance tests at once.
    # Use spec:acceptance to start the test with server started for you
    Rake::TestTask.new(:acceptance) do |t|
      t.description = '' # hide this task from `rake -T`
      t.pattern = 'spec/tests/acceptance/**/*_spec.rb'
      t.warning = false
    end
  end
end

namespace :spec do
  desc 'run all unit and integration tests at once'
  task :all do
    sh 'RACK_ENV=test bundle exec rake run:spec:all'
  end

  desc 'run all unit tests at once'
  task :unit do
    sh 'RACK_ENV=test bundle exec rake run:spec:unit'
  end

  desc 'run all integration tests at once'
  task :integration do
    sh 'RACK_ENV=test bundle exec rake run:spec:integration'
  end

  desc 'run all acceptance tests at once'
  task :accept do
    sh 'RACK_ENV=test buncle exec rake run:spec:acceptance'
  end
end

## ------ DATABASE ------ ##
namespace :db do
  def config_db(environment = nil)
    ENV['RACK_ENV'] = environment if environment # overwrite original env setting
    require 'sequel'
    require_relative 'config/environment' # load config info
    require_relative 'spec/helpers/database_helper'
    Skiller::App
  end

  desc 'list all db files'
  task :list do
    sh 'find app/infrastructure/database/local -name *.db -print'
  end

  # --- alias --- #
  desc 'run migrateions of the database in auto-detected environment'
  task migrate: 'migrate:exec'

  desc 'wipe all records in the database of auto-detected environment'
  task wipe: 'wipe:exec'

  desc 'delete the database of auto-detected environment'
  task drop: 'drop:exec'
  # [ END ] alias #

  namespace :migrate do
    task :exec, [:env] do |_, args|
      app = config_db(args[:env])
      Sequel.extension :migration
      puts "Migrating #{app.environment} database to latest"
      Sequel::Migrator.run(app.DB, 'app/infrastructure/database/migrations')
    end

    desc 'run migrations for development db'
    task :dev do
      Rake.application.invoke_task('db:migrate:exec[development]')
    end

    desc 'run migrations for test db'
    task :test do
      Rake.application.invoke_task('db:migrate:exec[test]')
    end
  end

  namespace :wipe do
    task :exec, [:env] do |_, args|
      app = config_db(args[:env])
      if app.environment == :production
        puts 'Do not damage production database!'
        return
      end

      require_relative 'spec/helpers/database_helper'
      puts "Wiping the #{app.environment} database"
      Skiller::DatabaseHelper.wipe_database
    end

    desc 'wipe all records in development db'
    task :dev do
      Rake.application.invoke_task('db:wipe:exec[development]')
    end

    desc 'wipe all records in test db'
    task :test do
      Rake.application.invoke_task('db:wipe:exec[test]')
    end
  end

  namespace :drop do
    task :exec, [:env] do |_, args|
      app = config_db(args[:env])
      if app.environment == :production
        puts 'Do not damage production database!'
        return
      end

      FileUtils.rm(app.config.DB_FILENAME)
      puts "#{app.config.DB_FILENAME} deleted"
    end

    desc 'delete development database'
    task :dev do
      Rake.application.invoke_task('db:drop:exec[development]')
    end

    desc 'delete test database'
    task :test do
      Rake.application.invoke_task('db:drop:exec[test]')
    end
  end
end

## ------ QUALITY ------ ##
namespace :quality do
  desc 'run all quality checks'
  task all: %i[rubocop flog reek]

  desc 'run rubocop check'
  task :rubocop do
    sh 'rubocop'
  end

  desc "run flog check of #{CODE}"
  task :flog do
    sh "flog -m #{CODE}"
  end

  desc 'run reek check'
  task :reek do
    sh 'reek'
  end
end

## ------ VCR ------ ##
namespace :vcr do
  desc 'list current casettes'
  task :list do
    sh "ls -1 #{CASSETTE_FOLDER}/*.yml"
  end

  desc 'delete all cassettes'
  task :clean do
    sh "rm #{CASSETTE_FOLDER}/*.yml" do |ok, _|
      puts(ok ? 'All cassettes deleted' : 'No cassette is found')
    end
  end
end

## ------ CACHE ------ ##
namespace :cache do
  desc 'list current cache'
  task :list do
    sh "find #{CACHE_FOLDER}/meta -print"
  end

  desc 'wipe all cache'
  task :wipe do
    sh "rm -rf #{CACHE_FOLDER}"
    sh "mkdir #{CACHE_FOLDER}"
    sh "mkdir #{CACHE_FOLDER}/body"
    sh "mkdir #{CACHE_FOLDER}/meta"
  end
end

## ------ SQS ------ ##
namespace :queues do
  def config_sqs(environment = nil)
    ENV['RACK_ENV'] = environment if environment # overwrite original env setting
    require 'aws-sdk-sqs'
    require_relative 'config/environment' # load config info
    @app = Skiller::App
    @sqs = Aws::SQS::Client.new(
      access_key_id: @app.config.AWS_ACCESS_KEY_ID,
      secret_access_key: @app.config.AWS_SECRET_ACCESS_KEY,
      region: @app.config.AWS_REGION
    )
  end

  # --- alias --- #
  desc 'report status of SQS queue with auto-detected environment'
  task status: 'status:exec'

  desc 'purge messages in SQS queue with auto-detected environment'
  task purge: 'purge:exec'
  # [ END ] alias #

  namespace :status do
    task :exec, [:env] do |_, args|
      config_sqs(args[:env])
      puts "loading status of #{@app.environment} queue..."
      q_url = @sqs.get_queue_url(queue_name: @app.config.EXTRACTOR_QUEUE).queue_url

      puts 'Queue info:'
      puts "  Name: #{@app.config.EXTRACTOR_QUEUE}"
      puts "  Region: #{@app.config.AWS_REGION}"
      puts "  URL: #{q_url}"
    rescue StandardError => e
      puts "Error while finding the queue: #{e}"
    end

    desc 'report status of development SQS queue'
    task :dev do
      Rake.application.invoke_task('queues:status:exec[development]')
    end

    desc 'report status of test SQS queue'
    task :test do
      Rake.application.invoke_task('queues:status:exec[test]')
    end
  end

  namespace :purge do
    task :exec, [:env] do |_, args|
      config_sqs(args[:env])
      puts "purging #{@app.config.EXTRACTOR_QUEUE} queue"
      q_url = @sqs.get_queue_url(queue_name: @app.config.EXTRACTOR_QUEUE).queue_url
      @sqs.purge_queue(queue_url: q_url)
    rescue StandardError => e
      puts "Error while purging the queue: #{e}"
    end

    desc 'Purge messages in development SQS queue'
    task :dev do
      Rake.application.invoke_task('queues:purge:exec[development]')
    end

    desc 'purge messages in test SQS queue'
    task :test do
      Rake.application.invoke_task('queues:purge:exec[test]')
    end
  end
end

## ------ WORKER ------ ##
namespace :worker do
  desc 'run the background worker in auto-detected mode'
  task run: 'run:exec'

  namespace :run do
    task :exec, [:env] do |_, args|
      ENV['RACK_ENV'] = args[:env] if args[:env] # overwrite original env setting
      require_relative 'config/environment' # load config info
      sh "bundle exec shoryuken -r ./workers/skill_extractor_worker.rb -q #{Skiller::App.config.EXTRACTOR_QUEUE_URL}"
    end

    desc 'run the background worker in development mode'
    task :dev do
      Rake.application.invoke_task('worker:run:exec[development]')
    end

    desc 'run the background worker in testing mode'
    task :test do
      Rake.application.invoke_task('worker:run:exec[test]')
    end

    desc 'run the background worker in production mode'
    task :prod do
      Rake.application.invoke_task('worker:run:exec[prod]')
    end
  end
end
