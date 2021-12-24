# frozen_string_literal: true

module SkillExtractor
  # Infrastructure to extract while yielding progress
  module ExtractMonitor
    EXTRACT_PROGRESS = {
      'STARTED'   => 15,
      'Extracting'   => 30,
      'remote'    => 70,
      'Receiving' => 85,
      'Resolving' => 95,
      'Checking'  => 100,
      'FINISHED'  => 100
    }.freeze

    def self.starting_percent
      EXTRACT_PROGRESS['STARTED'].to_s
    end

    def self.finished_percent
      EXTRACT_PROGRESS['FINISHED'].to_s
    end

    def self.progress(line)
      EXTRACT_PROGRESS[first_word_of(line)].to_s
    end

    def self.percent(stage)
      EXTRACT_PROGRESS[stage].to_s
    end

    def self.first_word_of(line)
      line.match(/^[A-Za-z]+/).to_s
    end
  end
end