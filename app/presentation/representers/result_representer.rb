# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

require_relative 'job_representer'
require_relative 'skill_representer'
require_relative 'salary_distribution_representer'

module Skiller
  module Representer
    # Job representer
    class Result < Roar::Decorator
      include Roar::JSON
      include Roar::Hypermedia
      include Roar::Decorator::HypermediaConsumer

      property :query
      collection :jobs, extend: Representer::Job, class: OpenStruct
      collection :skills, extend: Representer::Skill, class: OpenStruct
      property :salary_dist, extend: Representer::SalaryDistribution, class: OpenStruct

      link :self do
        "#{App.config.API_HOST}/some_path/#{project_name}/#{owner_name}"
      end

      private

      def project_name
        # represented.name
        'SOME'
      end

      def owner_name
        # represented.name
        'PATH'
      end
    end
  end
end
