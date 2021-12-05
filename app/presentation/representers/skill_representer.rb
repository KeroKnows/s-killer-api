# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

module Skiller
  module Representer
    # Salary representer
    class Skill < Roar::Decorator
      include Roar::JSON

      property :name
      property :salary, extend: Representer::Salary, class: Struct
    end
  end
end
