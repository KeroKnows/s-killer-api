# frozen_string_literal: true

folders = %w[database skill_extractor reed freecurrency cache messaging]
folders.each do |folder|
  require_relative "#{folder}/init.rb"
end
