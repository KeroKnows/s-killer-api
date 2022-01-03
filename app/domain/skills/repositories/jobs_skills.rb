# frozen_string_literal: true

module Skiller
  module Repository
    # Provide the access to jobs_skills table via `JobSkillOrm`
    class JobsSkills
      # Pull `Skill` entities according to a given db_id of a job.
      # The skills were parsed from the job.
      def self.find_skills_by_job_id(job_db_id)
        Database::JobSkillOrm.where(job_db_id: job_db_id).all.map do |job_skill|
          rebuild_skill_entity(job_skill)
        end
      end

      def self.rebuild_skill_entity(job_skill)
        return nil unless job_skill

        job = Jobs.rebuild_entity(job_skill.job)
        Skills.rebuild_entity(
          job_skill.skill,
          job.db_id,
          job.salary
        )
      end

      # Check if a given `Job` entity has been parsed and stored its skills to the table
      # Note: the `Job` entity should have a db_id which means it should rebuilt from the jobs table
      def self.job_exist?(job)
        Database::JobSkillOrm.first(job_db_id: job.db_id) ? true : false
      end

      def self.find_or_create(skills)
        skills.map do |skill|
          puts 'write skills'
          db_skill = Database::SkillOrm.find_or_create(skill.name)
          puts 'write jobs_skills'
          job_skill = Database::JobSkillOrm.find_or_create(skill.job_db_id, db_skill.id)
          rebuild_skill_entity(job_skill)
        end
      end
    end
  end
end
