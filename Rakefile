begin
  require 'bundler'
  Bundler::GemHelper.install_tasks
rescue Exception
end

task :test => %w(test:parallel test:non_parallel)

# memcached and redis specs cannot be used in parallel
# because of flushing and namespace lacking in redis

namespace :test do
  task :parallel do
    if defined?(JRUBY_VERSION)
      puts 'No tests executed in parallel in JRuby'
    else
      specs = Dir['spec/*/*_spec.rb'].reject {|s| s =~ /memcached|redis|client|shared|riak/ }
      sh("parallel_rspec -m 5 #{specs.join(' ')}")
    end
  end

  task :non_parallel do
    if defined?(JRUBY_VERSION)
      # Run all tests in jruby non-parallel
      sh('rspec spec/*/*_spec.rb')
    else
      specs = Dir['spec/*/*_spec.rb'].select {|s| s =~ /memcached|redis|client|shared|riak/ }
      sh("rspec #{specs.join(' ')}")
    end
  end
end

task :benchmarks do
  Dir.chdir('benchmarks')
  ruby('run.rb')
end

task :default => :test
