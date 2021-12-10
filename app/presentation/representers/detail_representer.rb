# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

require_relative 'salary_representer'

module Skiller
  module Representer
    # Detail representer
    class Detail < Roar::Decorator
      include Roar::JSON
      include Roar::Hypermedia
      include Roar::Decorator::HypermediaConsumer

      property :id
      property :title
      property :description
      property :location
      property :salary, extend: Representer::Salary, class: Struct
      property :url

      link :self do
        "#{App.config.API_HOST}/"
      end
    end
  end
end
