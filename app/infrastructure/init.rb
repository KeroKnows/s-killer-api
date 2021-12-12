# frozen_string_literal: true

folders = %w[database skill_extractor reed freecurrency cache]
folders.each do |folder|
  require_relative "#{folder}/init.rb"
end
