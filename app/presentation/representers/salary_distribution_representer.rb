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
      property :quantile_third
      property :quantile_first
      property :median
      property :mean
      property :std
      property :currency
    end
  end
end
