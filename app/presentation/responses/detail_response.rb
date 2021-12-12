# frozen_string_literal: true

module Skiller
  module Response
    # Result of a query
    Detail = Struct.new(:id, :title, :description, :location, :salary, :url)
  end
end
