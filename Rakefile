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
  specs = Dir['spec/*/*_spec.rb'].sort

  # FIXME:
  #
  # * QuickLZ segfaults because of an assertion
  #   QuickLZ is also not maintained on Github, but on Bitbucket
  #   and I don't know where the issue tracker is.
  #
  # * Cassandra show spurious failures
  #
  # * action_dispatch cannot be required for an unknown reason
  if ENV['TEST_GROUP']
    # Shuffle specs to ensure equal distribution over the test groups
    # We have to shuffle with the same seed every time because rake is started
    # multiple times!
    old_seed = srand(42)
    specs.shuffle!
    srand(old_seed)

    unstable = specs.select {|s| s =~ /quicklz|cassandra|action_dispatch/ }
    specs -= unstable
  end

  # Memcached and Redis specs cannot be used in parallel
  # because of flushing and lacking namespaces
  parallel = specs.reject {|s| s =~ /memcached|redis|client|shared|riak/ }
  serial = specs - parallel

  if ENV['TEST_GROUP'] =~ /^(\d+)\/(\d+)$/
    n = $1.to_i
    max = $2.to_i
    if n == max
      parallel = parallel[(n-1)*(parallel.size/max)..-1]
      serial = serial[(n-1)*(serial.size/max)..-1]
    else
      parallel = parallel[(n-1)*(parallel.size/max), parallel.size/max]
      serial = serial[(n-1)*(serial.size/max), serial.size/max]
    end
  elsif ENV['TEST_GROUP'] == 'unstable'
    parallel.clear
    serial = unstable
  end

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
    sleep 0.1 while threads.size >= 10
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
  ruby("script/benchmarks #{ENV['CONFIG']}")
end

task :default => :test
