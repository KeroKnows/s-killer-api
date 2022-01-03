# frozen_string_literal: true

module Skiller
  module Repository
    # Provide the access to jobs_skills table via `JobSkillOrm`
    class Skills
      def self.find_or_create(skill_name)
        db_skill = Database::SkillOrm.find_or_create(skill_name)
        rebuild_entity(db_skill, nil, nil)
      end

      def self.find_name(skill_name)
        db_skill = Database::SkillOrm.find(name: skill_name)
        rebuild_entity(db_skill, nil, nil)
      end

      def self.rebuild_entity(db_skill, job_db_id, salary)
        return nil unless db_skill

        Entity::Skill.new(
          id: db_skill.id,
          name: db_skill.name,
          job_db_id: job_db_id,
          salary: salary
        )
      end
    end
  end
end
