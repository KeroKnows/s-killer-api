# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

require_relative 'job_representer'
require_relative 'skill_representer'
require_relative 'salary_distribution_representer'

module Skiller
  module Representer
    # Result representer
    class Result < Roar::Decorator
      include Roar::JSON
      include Roar::Hypermedia
      include Roar::Decorator::HypermediaConsumer

      property :query
      collection :jobs, extend: Representer::Job, class: OpenStruct
      collection :skills, extend: Representer::Skill, class: OpenStruct
      property :salary_dist, extend: Representer::SalaryDistribution, class: OpenStruct

      link :self do
        # [ TODO ] add jobs' detail links
        "#{App.config.API_HOST}/"
      end
    end
  end
end
