task :test do
  # memcached and redis specs cannot be used in parallel
  # because of flushing and namespace lacking in redis
  specs = Dir['spec/*/*_spec.rb']
  parallel = specs.reject {|s| s =~ /memcached|redis|client|shared|riak/ }
  serial = specs - parallel
  parallel.each do |spec|
    sleep 0.1 while `ps -e -www -o pid,rss,command | grep '[r]spec'`.split("\n").size >= 10
    sh("rspec #{spec} &")
  end
  serial.each do |spec|
    sh("rspec #{spec}")
  end
end

task :benchmarks do
  Dir.chdir('benchmarks')
  ruby("run.rb #{ENV['CONFIG']}")
end

task :default => :test
