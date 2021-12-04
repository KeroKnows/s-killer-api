require 'roar/decorator'
require 'roar/json'

module Skiller
  module Representer
    # Salary representer
    class Salary < Roar::Decorator
      include Roar::JSON

      property :year_min
      property :year_max
      property :currency
    end
  end
end