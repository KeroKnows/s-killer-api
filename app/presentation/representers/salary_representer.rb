# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

module Skiller
  module Representer
    # Salary representer
    class Salary < Roar::Decorator
      include Roar::JSON

      property :year_max
      property :year_min
      property :currency
    end
  end
end
