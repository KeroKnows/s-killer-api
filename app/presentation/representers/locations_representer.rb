# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

require_relative 'salary_representer'

module Skiller
  module Representer
    # Locations representer
    class Locations < Roar::Decorator
      include Roar::JSON
      include Roar::Hypermedia

      collection :locations

      link :self do
        # [ TODO ] add jobs' detail links
        "#{App.config.API_HOST}/"
      end
    end
  end
end
