def rspec(spec)
  sh("rspec #{spec}")
  true
rescue Exception => ex
  if $?.termsig
    sig = nil
    Signal.list.each do |name, id|
      if id == $?.termsig
        sig = name
        break
      end
    end
    puts "\e[31m########## SIG#{sig} rspec #{spec} ##########\e[0m"
  end
  false
end

task :test do
  # memcached and redis specs cannot be used in parallel
  # because of flushing and namespace lacking in redis
  specs = Dir['spec/*/*_spec.rb']
  parallel = specs.reject {|s| s =~ /memcached|redis|client|shared|riak/ }
  serial = specs - parallel
  threads = []
  failed = false
  parallel.each do |spec|
    threads << Thread.new do
      begin
        failed = true unless rspec(spec)
      ensure
        threads.delete Thread.current
      end
    end
    sleep 0.1
    sleep 0.1 while threads.size >= 20
  end
  sleep 0.1 until threads.empty?
  serial.each do |spec|
    failed = true unless rspec(spec)
  end
  if failed
    fail "\e[31m########## MONETA TESTSUITE FAILED ##########\e[0m"
  else
    puts "\e[32m########## MONETA TESTSUITE SUCCEDED ##########\e[0m"
  end
end

task :benchmarks do
  Dir.chdir('benchmarks')
  ruby("run.rb #{ENV['CONFIG']}")
end

task :default => :test
