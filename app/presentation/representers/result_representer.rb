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
      collection :jobs, extend: Representer::Job, class: Struct
      collection :skills, extend: Representer::Skill, class: Struct
      property :salary_dist, extend: Representer::SalaryDistribution, class: Struct

      link :self do
        "#{App.config.API_HOST}/"
      end
    end
  end
end
