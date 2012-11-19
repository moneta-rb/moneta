begin
  require 'bundler'
  Bundler::GemHelper.install_tasks
rescue Exception
end

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib' << 'test'
  t.test_files = FileList['test/test_fog.rb']
  t.verbose = true
end

task :default => :test
