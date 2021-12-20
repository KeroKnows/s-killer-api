# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

require_relative 'salary_representer'

module Skiller
  module Representer
    # Job representer
    class Job < Roar::Decorator
      include Roar::JSON

      property :job_id
      property :db_id
      property :title
      property :description
      property :location
      property :salary, extend: Representer::Salary, class: OpenStruct
      property :url
      property :is_full
      property :is_analyzed
    end
  end
end
