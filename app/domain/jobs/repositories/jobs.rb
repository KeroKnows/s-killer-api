# frozen_string_literal: true

module Skiller
  module Repository
    # Provide the access to jobs table via `JobOrm`
    class Jobs
      def self.all
        Database::JobOrm.all.map { |db_job| rebuild_entity(db_job) }
      end

      def self.find(entity)
        find_db_id(entity.db_id)
      end

      # Find a job by a given db_id and return a rebuilted `Job` entity
      def self.find_db_id(db_id)
        rebuild_entity Database::JobOrm.first(db_id: db_id)
      end

      # Find a job by a given job_id and return a rebuilted `Job` entity
      def self.find_job_id(job_id)
        db_job = Database::JobOrm.first(job_id: job_id)
        rebuild_entity(db_job)
      end

      # Create a record in the table with a given `Job` entity
      # if the Job entity not stored to the table yet.
      # Then return a rebuilted `Job` entity
      def self.find_or_create(entity)
        rebuild_entity(Database::JobOrm.find_or_create(entity))
      end

      # Update the record of a given `Job` entity according to its db_id
      # Note: the entity should have a db_id
      def self.update(entity) # rubocop:disable Metrics/MethodLength
        db_id = entity.db_id
        salary = entity.salary
        Database::JobOrm.where(db_id: db_id).update(
          db_id: db_id,
          job_id: entity.job_id,
          job_title: entity.title,
          description: entity.description,
          location: entity.location,
          min_year_salary: salary.year_min,
          max_year_salary: salary.year_max,
          currency: salary.currency,
          job_level: entity.job_level,
          url: entity.url,
          is_full: entity.is_full,
          is_analyzed: entity.is_analyzed
        )
      end

      # Rebuild a `Job` entity from a given table record
      def self.rebuild_entity(db_job) # rubocop:disable Metrics/MethodLength
        return nil unless db_job

        Entity::Job.new(
          db_id: db_job.db_id,
          job_id: db_job.job_id,
          title: db_job.job_title,
          description: db_job.description,
          location: db_job.location,
          salary: {
            year_min: db_job.min_year_salary,
            year_max: db_job.max_year_salary,
            currency: db_job.currency
          },
          job_level: db_job.job_level,
          url: db_job.url,
          is_full: db_job.is_full,
          is_analyzed: db_job.is_analyzed
        )
      end
    end
  end
end
