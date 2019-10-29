# frozen_string_literal: true

require 'rake'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'rubocop-rspec'

RSpec::Core::RakeTask.new(:test) do |test|
  test.pattern = Dir.glob('spec/**/*.rb')
  test.rspec_opts = '--format documentation'
end

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['--display-cop-names', '--auto-correct']
end

task default: %i[test rubocop]
