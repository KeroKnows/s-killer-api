# frozen_string_literal: true

module Skiller
  module Response
    # the job analyzing request in between service and worker
    JobRequest = Struct.new :job, :id
  end
end
