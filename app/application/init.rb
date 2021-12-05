# frozen_string_literal: true

folders = %w[controllers requests services]
folders.each do |folder|
  require_relative "#{folder}/init"
end
