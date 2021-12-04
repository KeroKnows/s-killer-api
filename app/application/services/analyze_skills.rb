# frozen_string_literal: true

require 'dry/transaction'

module Skiller
  module Service
    # request the jobs related to given query, and analyze the skillset from it
    # :reek:TooManyStatements { max_statements: 7 } for Success/Failure and rescued statements
    class AnalyzeSkills
      include Dry::Transaction

      # [ TODO ] analyze skillset from more data
      ANALYZE_LEN = 10

      step :parse_request
      step :collect_jobs
      step :process_jobs
      step :collect_skills
      step :calculate_salary_distribution
      step :store_query_to_db
      step :to_response_object

      private

      # check if the previous form validation passes
      def parse_request(input)
        # puts input.value!["query"]
        query = input.value!["query"]
        if input.success?
          # Success(query: query)
          # Success(input)
          input
        else
          # Failure("Invalid query: '#{query}'")
          Failure("Invalid query: '#{input}'")
        end
      end

      # Collect jobs from database if the query has been searched;
      # otherwise, the entites will be created by mappers stored into the database
      # :reek:UncommunicativeVariableName for rescued error
      def collect_jobs(input)
        puts input["query"]
        # query = input.value!["query"]
        # input[:jobs] = search_jobs(query)
        input[:jobs] = search_jobs(input["query"])

        if input[:jobs].length.zero?
          Failure("No job is found with query #{input[:query]}")
        else
          Success(input)
        end
      rescue StandardError => e
        Failure("Fail to collect jobs: #{e}")
      end

      # Request full job description for future analysis
      # :reek:UncommunicativeVariableName for rescued error
      def process_jobs(input)
        jobs = input[:jobs]
        jobs[..ANALYZE_LEN] = jobs[..ANALYZE_LEN].map do |job|
          request_and_update_full_job(job)
        end
        Success(input)
      rescue StandardError => e
        Failure("Fail to process jobs: #{e}")
      end

      # Collect skills from database if the query has been searched;
      # otherwise, the entities will be created by mappers and stored into the database
      # :reek:UncommunicativeVariableName for rescued error
      def collect_skills(input)
        input[:skills] = search_skills(input)

        if input[:skills].length.zero?
          Failure("No skills are extracted from #{input[:query]}")
        else
          Success(input)
        end
      rescue StandardError => e
        Failure("Fail to extract skills: #{e}")
      end

      # Analyze the salary distribution from all related jobs
      # :reek:UncommunicativeVariableName for rescued error
      def calculate_salary_distribution(input)
        all_salary = input[:jobs].map(&:salary)
        input[:salary_dist] = Entity::SalaryDistribution.new(all_salary)
        Success(input)
      rescue StandardError => e
        Failure("Fail to analyze salary distribution: #{e}")
      end

      # Store the query-job
      # Note that this MUST be executed as the last step,
      #   when the jobs and skills are all correctly extracted,
      #   or the skills of new jobs will not be analyzed forever
      # :reek:UncommunicativeVariableName for rescued error
      def store_query_to_db(input)
        Repository::QueriesJobs.find_or_create(input[:query],
                                               input[:jobs].map(&:db_id))
        Success(input)
      rescue StandardError => e
        Failure("Fail to store query result: #{e}")
      end

      def to_response_object(input)
        puts input[:jobs][0].title
        puts input[:jobs][1].title
        puts input[:jobs][2].title
        # puts input[:jobs][3].title
        # puts input[:jobs][4].title
        # puts input[:jobs][5].title
        result_response = Response::Result.new(input[:query], input[:jobs], input[:salary_dist])
        # Success(input)
        Success(Response::ApiResult.new(status: :ok, message: result_response))
      end

      # ------ UTILITIES ------ #

      # search corresponding jobs in database first,
      # or request it through JobMapper
      def search_jobs(input)
        # query = input[:query]
        query = input
        if Repository::QueriesJobs.query_exist?(query)
          Repository::QueriesJobs.find_jobs_by_query(query)
        else
          request_jobs_and_update_database(query)
        end
      end

      # request full job description and update the information in database
      def request_and_update_full_job(job)
        return job if job.is_full

        full_job = Skiller::Reed::JobMapper.new(App.config).job(job.job_id, job)
        Repository::Jobs.update(full_job)
        Repository::Jobs.find(full_job)
      end

      # search corresponding skills in database first,
      # or extract it through SkillMapper
      def search_skills(input)
        query = input[:query]
        if Repository::QueriesJobs.query_exist?(query)
          Repository::QueriesJobs.find_skills_by_query(query)
        else
          extract_skills_and_update_database(input[:jobs][..ANALYZE_LEN])
        end
      end

      # request full job description from API and store into the database
      def request_jobs_and_update_database(query)
        job_mapper = Skiller::Reed::JobMapper.new(App.config)
        jobs = job_mapper.job_list(query)
        jobs.map do |job|
          Repository::Jobs.find_or_create(job)
        end
      end

      # analyze the jobs' required skills from mapper and store into the database
      def extract_skills_and_update_database(jobs)
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
  end
end
