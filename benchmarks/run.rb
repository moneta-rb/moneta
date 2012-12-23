#!/usr/bin/env ruby

$: << File.join(File.dirname(__FILE__), '..', 'lib')
require 'benchmark'
require 'moneta'

STORES = {
  :ActiveRecord => { :connection => { :adapter  => 'sqlite3', :database => 'bench.activerecord' } },
  :Cassandra => {},
  :Client => {},
  :Couch => {},
  :DBM => { :file => 'bench.dbm' },
  :DataMapper => { :setup => 'sqlite3:bench.datamapper' },
  :File => { :dir => 'bench.file' },
  :GDBM => { :file => 'bench.gdbm' },
  :HBase => {},
  :HashFile => { :dir => 'bench.hashfile' },
  :LRUHash => {},
  :LevelDB => { :dir => 'bench.leveldb' },
  :LocalMemCache => { :file => 'bench.lmc' },
  :MemcachedDalli => {},
  :MemcachedNative => {},
  :Memory => {},
  :Mongo => {},
  :PStore => { :file => 'bench.pstore' },
  :Redis => {},
  :Riak => {},
  # SDBM is unstable
  # :SDBM => { :file => 'bench.sdbm' },
  :Sequel => { :db => 'sqlite:/' },
  :Sqlite => { :file => ':memory:' },
  # YAML is so fucking slow
  # :YAML => { :file => 'bench.yaml' },
}

RUNS = 3
KEYS = 100
MIN_KEY_SIZE = 3
MAX_KEY_SIZE = 128
MIN_VALUE_SIZE = 1
MAX_VALUE_SIZE = 1024 * 10
DICT = 'ABCDEFGHIJKLNOPQRSTUVWXYZabcdefghijklnopqrstuvwxyz123456789'.freeze

class String
  def random(n)
    (1..n).map { self[rand(size),1] }.join
  end
end

class Array
  def sum
    inject(0, &:+)
  end

  def randomize
    rest, result = dup, []
    result << rest.slice!(rand(rest.size)) until result.size == size
    result
  end
end

Process.fork do
  begin
    Moneta::Server.new(Moneta.new(:Memory)).run
  rescue Exception => ex
    puts "\e[31mFailed to start Moneta server - #{ex.message}\e[0m"
  end
end
sleep 1 # Wait for server

STORES.each do |name, options|
  begin
    if name == :DataMapper
      begin
        require 'dm-core'
        DataMapper.setup(:default, :adapter => :in_memory)
      rescue LoadError => ex
        puts "\e[31mFailed to load DataMapper - #{ex.message}\e[0m"
      end
    elsif name == :Riak
      require 'riak'
      Riak.disable_list_keys_warnings = true
    end

    cache = Moneta.new(name, options.dup)
    cache['test'] = 'test'
  rescue Exception => ex
    puts "\e[31m#{name} not benchmarked - #{ex.message}\e[0m"
    STORES.delete(name)
  ensure
    cache.close if cache
  end
end

HEADER = "\n                         Minimum  Maximum    Total  Average    Ops/s"
SEPARATOR = '=' * 68

puts "\e[1m\e[34m#{SEPARATOR}\n\e[34mComparison of write/read between Moneta Stores\n\e[34m#{SEPARATOR}\e[0m"

stats, keys, data, summary = {}, [], [], []

KEYS.times do |x|
  key_size = rand(MAX_KEY_SIZE - MIN_KEY_SIZE) + MIN_KEY_SIZE
  val_size = rand(MAX_VALUE_SIZE - MIN_VALUE_SIZE) + MIN_VALUE_SIZE

  key = DICT.random(key_size)
  keys << key
  data << [key, DICT.random(val_size)]
end

puts %{Total keys: #{keys.size}, Unique keys: #{keys.uniq.size}
                         Minimum  Maximum    Total  Average}
key_sizes = data.map(&:first).map(&:size)
val_sizes = data.map(&:last).map(&:size)
puts 'Key Length              % 8d % 8d % 8d % 8d ' % [key_sizes.min, key_sizes.max, key_sizes.sum, key_sizes.sum / KEYS]
puts 'Value Length            % 8d % 8d % 8d % 8d ' % [val_sizes.min, val_sizes.max, val_sizes.sum, val_sizes.sum / KEYS]

STORES.each do |name, options|
  begin
    puts "\n\e[1m\e[34m#{SEPARATOR}\n\e[34m#{name}\n\e[34m#{SEPARATOR}\e[0m"

    cache = Moneta.new(name, options.dup)

    stats[name] = {
      :write => [],
      :read => [],
      :sum => [],
      :error => []
    }

    %w(Rehearse Measure).each do |type|
      state = ''
      print "%s [%#{2 * RUNS}s] " % [type, state]

      RUNS.times do |run|
        cache.clear
        print "%s[%-#{2 * RUNS}s] " % ["\b" * (2 * RUNS + 3), state << 'W']

        data = data.randomize
        m1 = Benchmark.measure do
          data.each {|k,v| cache[k] = v }
        end

        print "%s[%-#{2 * RUNS}s] " % ["\b" * (2 * RUNS + 3), state << 'R']

        data = data.randomize
        error = 0
        m2 = Benchmark.measure do
          data.each do |k, v|
            error += 1 if v != cache[k]
          end
        end

        if type == 'Measure'
          stats[name][:write] << m1.real
          stats[name][:error] << error
          stats[name][:read] << m2.real
          stats[name][:sum] << (m1.real + m2.real)
        end
      end
    end

    puts HEADER
    [:write, :read, :sum].each do |i|
      total = stats[name][i].sum
      ops = (RUNS * KEYS) / total
      line = '%-17.17s %-5s % 8d % 8d % 8d % 8d % 8d' %
        [name, i, stats[name][i].min * 1000, stats[name][i].max * 1000,
         total * 1000, total * 1000 / RUNS, ops]
      summary << [-ops, line << "\n"] if i == :sum
      puts line
    end

    errors = stats[name][:error].sum
    if errors > 0
      puts "\e[31m%-23.23s % 8d % 8d % 8d % 8d\e[0m" %
        ['Read errors', stats[name][:error].min, stats[name][:error].max, errors, errors / RUNS]
    else
      puts "\e[32mNo read errors"
    end
  rescue StandardError => ex
    puts "\n\e[31mFailed to benchmark #{name} - #{ex.message}\e[0m\n"
  ensure
    cache.close if cache
  end
end

puts "\n\e[1m\e[34m#{SEPARATOR}\n\e[34mSummary: #{RUNS} runs, #{KEYS} keys\n\e[34m#{SEPARATOR}\e[0m#{HEADER}\n"
summary.sort_by(&:first).each do |entry|
  puts entry.last
end
