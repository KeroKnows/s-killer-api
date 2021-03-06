# frozen_string_literal: true

module Skiller
  module Service
    # An utility class that handle job processing in the service
    class Utility
      ANALYZE_LEN = 10
      CONFIG = Skiller::App.config
      SQS = Skiller::Messaging::Queue.new(CONFIG.EXTRACTOR_QUEUE_URL, CONFIG)

      # search corresponding jobs in database first,
      # or request it through JobMapper
      def self.search_jobs(input)
        query = input[:query]
        if Repository::QueriesJobs.query_exist?(query)
          Repository::QueriesJobs.find_jobs_by_query(query)
        else
          jobs = request_jobs_and_update_database(query)
          store_query_to_db(query, jobs)
          jobs
        end
      end

      def self.all_jobs_analyzed?(jobs)
        jobs[...ANALYZE_LEN].all?(&:is_analyzed)
      end

      def self.not_analyzed_jobs(jobs)
        ANALYZE_LEN - jobs[...ANALYZE_LEN].count(&:is_analyzed)
      end

      def self.store_query_to_db(query, jobs)
        Repository::QueriesJobs.find_or_create(query, jobs.map(&:db_id))
      end

      def self.find_skills_by_jobs(jobs)
        jobs.map { |job| Skiller::Repository::JobsSkills.find_skills_by_job_id(job.db_id) }
            .reduce(&:+)
      end

      # request full job description and update the information in database
      def self.request_and_update_full_job(job)
        return job if job.is_full

        full_job = Skiller::Reed::JobMapper.new(App.config).job(job.job_id, job)
        Repository::Jobs.update(full_job)
        Repository::Jobs.find(full_job)
      end

      # search corresponding skills in database first,
      # or extract it through SkillMapper
      def self.search_skills(input)
        query = input[:query]
        if Repository::QueriesJobs.query_exist?(query)
          Repository::QueriesJobs.find_skills_by_query(query)
        else
          jobs = input[:jobs][...ANALYZE_LEN]
          jobs.map(&method(:extract_skills_and_update_database))
              .reduce(:+)
        end
      end

      # request partial job description from API and store into the database
      def self.request_jobs_and_update_database(query)
        job_mapper = Skiller::Reed::JobMapper.new(App.config)
        jobs = job_mapper.job_list(query)
        jobs.map do |job|
          Repository::Jobs.find_or_create(job)
        end
      end

      def self.job_json(job, request_id)
        Skiller::Response::JobRequest.new(job, request_id)
                                     .then { |req| Skiller::Representer::ExtractRequest.new(req) }
                                     .then(&:to_json)
      end

      def self.extract_skills_with_worker(jobs, request_id)
        jobs.map do |job|
          Concurrent::Promise.new { request_and_update_full_job(job) }
                             .then { |full_job| SQS.send(job_json(full_job, request_id)) }
                             .rescue { |err| puts err }
                             .execute
        end
      end

      # analyze the jobs' required skills from mapper and store into the database
      def self.extract_skills_and_update_database(job)
        if Repository::JobsSkills.job_exist?(job)
          Repository::JobsSkills.find_skills_by_job_id(job.db_id)
        else
          skills = Skiller::Skill::SkillMapper.new(job).skills
          Repository::JobsSkills.find_or_create(skills)
        end
      end

      def self.find_skills_by_skillset(skillset)
        skillset.map { |name| Repository::JobsSkills.find_skills_by_name(name) }
                .reduce(&:+)
      end

      def self.find_jobs_by_skills(skills)
        skills.map(&:job_db_id).uniq.map { |job_db_id| Skiller::Repository::Jobs.find_db_id(job_db_id) }
      end
    end
  end
end
