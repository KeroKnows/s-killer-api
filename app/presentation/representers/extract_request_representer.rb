# frozen_string_literal: true

require 'roar/decorator'
require 'roar/json'

require_relative 'job_representer'

# Represents essential Repo information for API output
module Skiller
  module Representer
    # Representer object for project clone requests
    class ExtractRequest < Roar::Decorator
      include Roar::JSON

      property :job, extend: Representer::Job, class: OpenStruct
      property :id
    end
  end
end