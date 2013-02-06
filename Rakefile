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

  # Shuffle specs to ensure equal distribution over the test groups
  # We have to shuffle with the same seed every time because rake is started
  # multiple times!
  old_seed = srand(43)
  specs.shuffle!
  srand(old_seed)

  group = ENV['TEST_GROUP'] || '1/1'

  # FIXME:
  #
  # * QuickLZ segfaults because of an assertion
  #   QuickLZ is also not maintained on Github, but on Bitbucket
  #   and I don't know where the issue tracker is.
  #
  # * Cassandra and Riak fail spuriously (An expert has to check the adapters!)
  #
  # * ActiveRecord has some connection problems (An expert has to check the adapter!)
  #
  # * Transformer with uuencode fails under JRuby
  #
  # * PStore and File increment/locking doesn't work correctly on JRuby
  #
  if defined?(JRUBY_VERSION)
    unstable = specs.select {|s| s =~ /quicklz|cassandra|riak|activerecord|uuencode|file|pstore/ }
  else
    unstable = specs.select {|s| s =~ /quicklz|cassandra|riak|activerecord/ }
  end
  specs -= unstable

  if group =~ /^(\d+)\/(\d+)$/
    n = $1.to_i
    max = $2.to_i
    if n == max
      specs = specs[(n-1)*(specs.size/max)..-1]
    else
      specs = specs[(n-1)*(specs.size/max), specs.size/max]
    end
  elsif group == 'unstable'
    specs = unstable
  else
    puts "Invalid test group #{group}"
    exit 1
  end

  # Memcached and Redis specs cannot be used in parallel
  # because of flushing and lacking namespaces
  parallel = []
  %w(memcached redis client shared riak tokyotyrant couch cassandra).each do |name|
    serial = specs.select { |s| s.include?(name) }
    unless serial.empty?
      specs -= serial
      parallel << serial
    end
  end
  parallel += specs.map {|s| [s] }

  threads = []
  failed = false
  parallel.each do |serial|
    threads << Thread.new do
      begin
        serial.each do |spec|
          failed = true unless rspec(spec)
        end
      ensure
        threads.delete Thread.current
      end
    end
    sleep 0.1
    sleep 0.1 while threads.size >= 10
  end
  sleep 0.1 until threads.empty?
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
