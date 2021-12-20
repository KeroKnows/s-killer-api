# frozen_string_literal: true

require_relative '../../entities/job'

module Skiller
  module Reed
    # Get an array of `Job` using Reed::Api
    class JobMapper
      def initialize(config, gateway_class = Reed::Api)
        @config = config
        @gateway = gateway_class.new(@config.REED_TOKEN)
      end

      # Get job_list from Reed::API and make each job a DataMapper class
      def job_list(keyword)
        data = @gateway.search(keyword)['results']
        data.map { |job_data| DataMapper.new(job_data, false).build_entity }
      end

      # Get job from Reed::API and make the job a DataMapper class
      def job(job_id, inheritance = nil)
        data = @gateway.details(job_id)
        DataMapper.new(data, true, inheritance).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(data, is_full, inheritance = nil)
          @data = data
          @inheritance = inheritance
          @is_full = is_full
        end

        def build_entity # rubocop:disable Metrics/MethodLength
          Entity::Job.new(
            db_id: @inheritance&.db_id,
            job_id: @data['jobId'],
            title: @data['jobTitle'],
            description: @data['jobDescription'],
            location: @data['locationName'],
            salary: {
              year_min: @data['yearlyMinimumSalary'],
              year_max: @data['yearlyMaximumSalary'],
              currency: @data['currency']
            },
            url: @data['jobUrl'],
            is_full: @is_full,
            is_analyzed: false
          )
        end
      end
    end
  end
end
