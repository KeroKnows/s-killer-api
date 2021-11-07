# frozen_string_literal: true

require 'sequel'

Sequel.migration do
  change do
    create_table(:jobs) do
      # Method name # Column
      primary_key :id

      String      :job_id, unique: true
      String      :job_title
      String      :description
      String      :location
      Float       :min_year_salary
      Float       :max_year_salary
      String      :currency
      String      :url, null: true

      DateTime    :created_at
      DateTime    :updated_at
      String      :updated_by
    end
  end
end