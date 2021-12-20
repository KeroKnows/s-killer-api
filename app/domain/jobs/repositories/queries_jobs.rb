# frozen_string_literal: true

module Skiller
  module Repository
    # Provide the access to queries_jobs table via `QueryJobOrm`
    class QueriesJobs
      # Pull `Job` entities according to a given query
      def self.find_jobs_by_query(query)
        Database::QueryJobOrm.where(query: query).all.map do |query_job|
          Jobs.rebuild_entity(query_job.job)
        end
      end

      # Pull `Skill` entities according to a given query
      def self.find_skills_by_query(query)
        skill_list = Database::QueryJobOrm.where(query: query).all.map do |query_job|
          JobsSkills.find_skills_by_job_id(query_job.job_db_id)
        end
        skill_list.reduce(:+)
      end

      # Check if a query has been stored to the table with its related jobs
      def self.query_exist?(query)
        if Database::QueryJobOrm.first(query: query)
          true
        else
          false
        end
      end

      # Create (query, job_db_id) records given a query and its related job_db_ids
      def self.find_or_create(query, job_db_ids)
        job_db_ids.map do |job_db_id|
          Database::QueryJobOrm.find_or_create(query, job_db_id)
        end
      end
    end
  end
end
