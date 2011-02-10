require 'rubygems'
require 'bundler'
Bundler.setup

Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
desc "Run all examples (or a specific spec with TASK=xxxx)"
RSpec::Core::RakeTask.new(:examples) do |c|
  c.rspec_opts = '-Ispec'
end

task :default => :examples
