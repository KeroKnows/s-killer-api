# frozen_string_literal: true

require 'sequel'

module Skiller
  module Database
    # Object Relational Mapper for Job and Entities
    class JobOrm < Sequel::Model(:jobs)
      one_to_many :skills,
                  class: :'Skiller::Database::JobSkillOrm',
                  key: :job_db_id
      # setting the update timestamp when creating
      plugin :timestamps, update_on_create: true

      def self.find_or_create(job) # rubocop:disable Metrics/MethodLength
        salary = job.salary
        job_id = job.job_id
        first(job_id: job_id) || create(
          job_id: job_id,
          job_title: job.title,
          description: job.description,
          location: job.location,
          min_year_salary: salary.year_min,
          max_year_salary: salary.year_max,
          currency: salary.currency,
          job_level: job.job_level,
          url: job.url,
          is_full: job.is_full,
          is_analyzed: job.is_analyzed
        )
      end
    end
  end
end
