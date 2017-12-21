require 'bundler/setup'
require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
RSpec::Core::RakeTask.new(:coverage) do |c|
  c.ruby_opts = '-r ./spec/coverage_helper'
end

require 'yard'
YARD::Rake::YardocTask.new

desc 'Default: run specs.'
task :default => :spec
