# frozen_string_literal: true

require 'descriptive_statistics'
module Skiller
  module Entity
    # An entity object to estimate the statistical distribution of given salaries
    class SalaryDistribution
      attr_reader :maximum, :minimum, :currency, :quantile_75, :quantile_25, :median, :mean, :std

      # The argument `currency` is the currency to which the `salaries` (an array of `Salary`) need to be exchanged
      # For example, `sd = SalaryDistribution.new(salaries, 'TWD')`
      # means the `salaries` would be exchanged to TWD so that the `salaries`` could be compared fairly
      def initialize(salaries, currency = 'TWD')
        @currency = currency
        @salaries = salaries.map do |salary|
          salary.exchange_currency(@currency)
        end
        @salary_midpoints = calculate_salary_midpoints
        @maximum = calculate_maximum
        @quantile_75 = calculate_quantile_75
        @median = calculate_median
        @quantile_25 = calculate_quantile_25
        @minimum = calculate_minimum
        @mean = calculate_mean
        @std = calculate_std
      end

      def calculate_salary_midpoints
        salary_midpoints = []
        @salaries.each do |salary|
          year_min = salary.year_min
          year_max = salary.year_max
          if year_min && !year_max
            salary_midpoints << salary.year_min
          elsif !year_min && year_max
            salary_midpoints << year_max
          elsif year_min && year_max
            salary_midpoints << (year_min + year_max) / 2
          end
        end
        salary_midpoints
      end

      def calculate_maximum
        salaries = filter_salary(:year_max)
        salaries.max_by(&:year_max)&.year_max
      end

      def calculate_minimum
        salaries = filter_salary(:year_min)
        salaries.min_by(&:year_min)&.year_min
      end

      def calculate_quantile_75
        @salary_midpoints.percentile(75)
      end

      def calculate_median
        @salary_midpoints.median
      end

      def calculate_quantile_25
        @salary_midpoints.percentile(25)
      end

      def calculate_mean
        @salary_midpoints.mean
      end

      def calculate_std
        @salary_midpoints.standard_deviation
      end


      # Select the salaries which `prop` is not nils
      def filter_salary(prop)
        @salaries.filter(&prop)
      end
    end
  end
end
