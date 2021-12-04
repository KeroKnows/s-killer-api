require 'roar/decorator'
require 'roar/json'

require_relative 'salary_representer'

module Skiller
  module Representer
    # Skill representer
    class Skill < Roar::Decorator
      include Roar::JSON

      property :name
      property :salary, extend: Representer::Salary, class: OpenStruct
    end
  end
end