# frozen_string_literal: true

module Skiller
  module Entity
    # An entity object to estimate the statistical distribution of given salaries
    class SalaryDistribution
      attr_reader :maximum, :minimum, :currency

      # The argument `currency` is the currency to which the `salaries` (an array of `Salary`) need to be exchanged
      # For example, `sd = SalaryDistribution.new(salaries, 'TWD')`
      # means the `salaries` would be exchanged to TWD so that the `salaries`` could be compared fairly
      def initialize(salaries, currency = 'TWD')
        @currency = currency
        @salaries = salaries.map do |salary|
          salary.exchange_currency(@currency)
        end
        @maximum = calculate_maximum
        @minimum = calculate_minimum
      end

      def calculate_maximum
        salaries = filter_salary(:year_max)
        salaries.max_by(&:year_max)&.year_max
      end

      def calculate_minimum
        salaries = filter_salary(:year_min)
        salaries.min_by(&:year_min)&.year_min
      end

      # Select the salaries which `prop` is not nils
      def filter_salary(prop)
        @salaries.filter(&prop)
      end
    end
  end
end
