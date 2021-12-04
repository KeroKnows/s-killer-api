# frozen_string_literal: true

module Skiller
  module Response
    # Result of a query
    Result = Struct.new(:query, :jobs, :salary_dist)
  end
end