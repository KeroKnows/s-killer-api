# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

module Skiller
  module Representer
    # Salary Distribution representer
    class SalaryDistribution < Roar::Decorator
      include Roar::JSON

      property :maximum
      property :minimum
      property :currency
    end
  end
end
