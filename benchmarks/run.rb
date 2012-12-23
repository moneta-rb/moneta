#!/usr/bin/env ruby

$: << File.join(File.dirname(__FILE__), '..', 'lib')
require 'benchmark'
require 'moneta'

begin
  require 'dm-core'
  DataMapper.setup(:default, :adapter => :in_memory)
rescue LoadError => ex
  puts "Failed to load DataMapper - #{ex.message}"
end

Process.fork do
  begin
    Moneta::Server.new(Moneta.new(:Memory)).run
  rescue Exception => ex
    puts "Failed to start Moneta server - #{ex.message}"
  end
end
sleep 1 # Wait for server

class String
  def random(n)
    (1..n).map { self[rand(size),1] }.join
  end
end

class Array
  def randomize
    rest, result = dup, []
    result << rest.slice!(rand(rest.size)) until result.size == size
    result
  end
end

stores = {
  :ActiveRecord => { :connection => { :adapter  => 'sqlite3', :database => 'bench.activerecord' } },
  :Cassandra => {},
  :Client => {},
  :Couch => {},
  :DBM => { :file => 'bench.dbm' },
  :DataMapper => { :setup => 'sqlite3:bench.datamapper' },
  :File => { :dir => 'bench.file' },
  :GDBM => { :file => 'bench.gdbm' },
  :HBase => {},
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
  :SDBM => { :file => 'bench.sdbm' },
  :Sequel => { :db => 'sqlite:/' },
  :Sqlite => { :file => 'bench.sqlite' },
  :YAML => { :file => 'bench.yaml' },
}

stats, keys, data, errors, summary = {}, [], [], [], []
dict = 'ABCDEFGHIJKLNOPQRSTUVWXYZabcdefghijklnopqrstuvwxyz123456789'
vlen_min, vlen_max, vlen_total = 99999, 0, 0
klen_min, klen_max, klen_total = 99999, 0, 0

RUNS = 3
KEYS = 100
MIN_KEY_SIZE = 3
MAX_KEY_SIZE = 64
MIN_VALUE_SIZE = 1
MAX_VALUE_SIZE = 1024 * 10

puts '======================================================================'
puts 'Comparison of write/read between Moneta Stores'
puts '======================================================================'

stores.each do |name, options|
  begin
    cache = Moneta.new(name, options.dup)
    cache['test'] = 'test'
  rescue Exception => ex
    puts "#{name} not benchmarked - #{ex.message}"
    stores.delete(name)
  ensure
    cache.close if cache
  end
end

puts 'Data loading...'
KEYS.times do |x|
  klen = rand(MAX_KEY_SIZE - MIN_KEY_SIZE) + MIN_KEY_SIZE
  vlen = rand(MAX_VALUE_SIZE - MIN_VALUE_SIZE) + MIN_VALUE_SIZE

  key = dict.random(klen)
  value = dict.random(vlen)

  keys << key
  data << [key, value]

  vlen_min = value.size if value.size < vlen_min
  vlen_max = value.size if value.size > vlen_max
  vlen_total = vlen_total + value.size

  klen_min = key.size if key.size < klen_min
  klen_max = key.size if key.size > klen_max
  klen_total = klen_total + key.size
end

puts '----------------------------------------------------------------------'
puts "Total keys: #{keys.size}, unique: #{keys.uniq.size}"
puts '----------------------------------------------------------------------'
puts '                  Minimum    Maximum      Total    Average        xps '
puts '----------------------------------------------------------------------'
puts 'Key Length     % 10i % 10i % 10i % 10i ' % [klen_min, klen_max, klen_total, klen_total / KEYS]
puts 'Value Length   % 10i % 10i % 10i % 10i ' % [vlen_min, vlen_max, vlen_total, vlen_total / KEYS]

stores.each do |name, options|
  begin
    puts '======================================================================'
    puts name
    puts '----------------------------------------------------------------------'
    cache = Moneta.new(name, options.dup)

    stats[name] = {
      :writes => [],
      :reads => [],
      :totals => [],
      :averages => [],
    }

    RUNS.times do |round|
      cache.clear
      print "[#{round + 1}] W"
      m1 = Benchmark.measure do
        data.randomize.each do |key, value|
          cache[key] = value
        end
      end
      stats[name][:writes] << m1.real
      print 'R '
      m2 = Benchmark.measure do
        data.randomize.each do |key, value|
          res = cache[key]
          errors << [name, key, value, res] unless res == value
        end
      end
      stats[name][:reads] << m2.real
      stats[name][:totals] << (m1.real + m2.real)
      stats[name][:averages] << (m1.real + m2.real)
    end
    puts ''
    puts '----------------------------------------------------------------------'
    puts '                  Minimum    Maximum      Total    Average        xps '
    puts '----------------------------------------------------------------------'
    tcmin, tcmax, tctot, tcavg = 99999, 0, 0, 0
    [:writes, :reads].each do |sname|
      cmin, cmax, ctot, cavg = 99999, 0, 0, 0
      stats[name][sname].each do |val|
        cmin = val if val < cmin
        tcmin = val if val < tcmin
        cmax = val if val > cmax
        tcmax = val if val > tcmax
        ctot = ctot + val
        tctot = tctot + val
      end
      cavg = ctot / RUNS
      puts '%-14.14s % 10.4f % 10.4f % 10.4f % 10.4f % 10.4f ' % ["#{name} #{sname}", cmin, cmax, ctot, cavg, KEYS / cavg]
    end
    tcavg = tctot / (RUNS * 2)
    puts '%-14.14s % 10.4f % 10.4f % 10.4f % 10.4f % 10.4f ' % ["#{name} avgs", tcmin, tcmax, tctot, tcavg, KEYS / tcavg]
    summary << [name, tcmin, tcmax, tctot, tcavg, KEYS / tcavg]
  rescue Exception => ex
    puts "Failed to benchmark #{name} - #{ex.message}"
  ensure
    cache.close if cache
  end
end
puts '----------------------------------------------------------------------'
if errors.size > 0
  puts "Errors : #{errors.size}"
#  puts errors.inspect
else
  puts 'No errors in reading!'
end
puts '======================================================================'
puts "Summary: #{RUNS} runs, #{KEYS} keys"
puts '======================================================================'
puts '                  Minimum    Maximum      Total    Average        xps '
puts '----------------------------------------------------------------------'
summary.each do |sry|
  puts '%-14.14s % 10.4f % 10.4f % 10.4f % 10.4f % 10.4f ' % sry
end
