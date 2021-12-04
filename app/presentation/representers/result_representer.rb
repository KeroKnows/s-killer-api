require 'roar/decorator'
require 'roar/json'

require_relative 'job_representer'
require_relative 'skill_representer'

module Skiller
  module Representer
    # Job representer
    class Result < Roar::Decorator
      include Roar::JSON

      # property :query
      # property :jobs
    #   property :job, extend: Representer::Job, class: OpenStruct
    #   property :skill, extend: Representer::Skill, class: OpenStruct
      # property :test_title
      property :jobs
      property :query
      property :salary_dist

    end
  end
end