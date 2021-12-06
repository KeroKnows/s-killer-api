# frozen_string_literal: true

require 'yaml'
require 'nokogiri'

module Skiller
  module Skill
    # Extract the skillset from Skiller::Entity::Job
    class Extractor
      PYTHON = 'python3' # may need to change this to `python`, depending on your system
      SCRIPT = File.join(File.dirname(__FILE__), 'extract.py')

      attr_reader :description

      def initialize(job)
        @description = job.description
        @random_seed = rand(10_000)
        @script_result = nil
      end

      def skills
        analyze_skills
        YAML.safe_load(@script_result)
      end

      def analyze_skills
        tmp_file = File.join(File.dirname(__FILE__), ".extractor.#{@random_seed}.tmp")
        File.write(tmp_file, description, mode: 'w')
        @script_result = `#{PYTHON} #{SCRIPT} "#{tmp_file}"`
        File.delete(tmp_file)
      end
    end
  end
end
