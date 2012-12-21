#!/usr/bin/env ruby

$: << File.join(File.dirname(__FILE__), '..', 'lib')
require 'benchmark'
require 'moneta'

begin
  require 'dm-core'
  DataMapper.setup(:default, :adapter => :in_memory)
rescue LoadError
end

# Array modifications
class Array
  # Random keys/values
  attr_reader :keys_used
  def random_key(no_repeat = true, clean_keys_used = false)
    @keys_used = [] if clean_keys_used or @keys_used.nil? or @keys_used.size == self.size
    begin key = rand(self.size) end while no_repeat and @keys_used.include?(key)
    @keys_used << key
    return key
  end

  def random_value(no_repeat = true, clean_keys_used = false)
    values_at(random_key(no_repeat, clean_keys_used)).first
  end
  alias_method :random, :random_value

  def random_subset(n, no_repeat = true, clean_keys_used = true)
    (1..n).map{|x| random_value(no_repeat, (clean_keys_used && x == 1))}
  end

  def self.new_from_string(str)
    res = new
    str.split('').each{|x| res << x}
    res
  end
end

stores = {
  :ActiveRecord => { :connection => { :adapter  => 'sqlite3', :database => ':memory:' } },
  :Client => { },
  :Couch => {:db => 'couch_test'},
  :DBM => { :file => 'bench.dbm' },
  :DataMapper => { :setup => 'sqlite3::memory:' },
  :File => { :dir => 'bench.file' },
  :GDBM => { :file => 'bench.gdbm' },
  :HBase => { },
  :HashFile => { :dir => 'bench.hashfile' },
  :LRUHash => { },
  :LevelDB => { :dir => 'bench.leveldb' },
  :LocalMemCache => { :file => 'bench.lmc' },
  :MemcachedDalli => { :server => 'localhost:11211', :namespace => 'moneta_dalli' },
  :MemcachedNative => { :server => 'localhost:11211', :namespace => 'moneta_native' },
  :Memory => { },
  :Mongo => { :host => 'localhost', :port => 27017, :db => 'moneta_bench' },
  :PStore => { :file => 'bench.pstore' },
  :Redis => { },
  :Riak => { },
  :SDBM => { :file => 'bench.sdbm' },
  :Sequel => { :db => 'sqlite:/' },
  :Sqlite => { :file => ':memory:' },
  :YAML => { :file => 'bench.yaml' },
}

stats, keys, data, errors, summary = {}, [], [], [], []
dict = Array.new_from_string 'abcdefghijklnopq123456789'
n = ARGV[0] ? ARGV[0].to_i : 100
m = ARGV[1] ? ARGV[1].to_i : 10
c = ARGV[2] ? ARGV[2].to_i : 3
vlen_min, vlen_max, vlen_ttl, vlen_avg = 99999, 0, 0, 0
ds = dict.size

puts '======================================================================'
puts 'Comparison of write/read between Moneta Stores'
puts '======================================================================'

puts 'Data loading...'
n.times do |x|
  klen = 6 + rand(3)
  vlen = (rand(m) + 1) * (rand(m) + rand(m) + 1)
  key = dict.random_subset(klen).join
  keys << key
  value = key * vlen
  data << [key, value]
  vs = value.size
  vlen_min = vs if vs < vlen_min
  vlen_max = vs if vs > vlen_max
  vlen_ttl = vlen_ttl + vs
end
vlen_avg = vlen_ttl / n

puts '----------------------------------------------------------------------'
#puts data.inspect
puts "Total keys: #{keys.size}, unique: #{keys.uniq.size}"
#puts keys.sort.inspect

puts '----------------------------------------------------------------------'
puts '                  Minimum    Maximum      Total    Average        xps '
puts '----------------------------------------------------------------------'
puts 'Lenght Stats   % 10i % 10i % 10i % 10i ' % [vlen_min, vlen_max, vlen_ttl, vlen_avg]


stores.each do |name, options|
  begin
    @cache = Moneta.new(name, options)
    @cache['test'] = 'test'
    @cache.clear
  rescue Exception => ex
    puts "#{name} not benchmarked - #{ex.message}"
    next
  end
  puts '======================================================================'
  puts name
  puts '----------------------------------------------------------------------'
  stats[name] = {
    :writes => [],
    :reads => [],
    :totals => [],
    :avgs => [],
  }
  c.times do |round|
    @cache.clear
    print "[#{round + 1}] R"
    m1 = Benchmark.measure do
      n.times do
        key, value = data.random

        @cache[key] = value
      end
    end
    stats[name][:writes] << m1.real
    print 'W '
    m2 = Benchmark.measure do
      n.times do
        key, value = data.random
        res = @cache[key]
        errors << [name, key, value, res] unless res == value
      end
    end
    stats[name][:reads] << m2.real
    stats[name][:totals] << (m1.real + m2.real)
    stats[name][:avgs] << (m1.real + m2.real)
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
    cavg = ctot / c
    puts '%-14.14s % 10.4f % 10.4f % 10.4f % 10.4f % 10.4f ' % ["#{name} #{sname}", cmin, cmax, ctot, cavg, n / cavg]
  end
  tcavg = tctot / (c * 2)
  puts '%-14.14s % 10.4f % 10.4f % 10.4f % 10.4f % 10.4f ' % ["#{name} avgs", tcmin, tcmax, tctot, tcavg, n / tcavg]
  summary << [name, tcmin, tcmax, tctot, tcavg, n / tcavg]
end
puts '----------------------------------------------------------------------'
if errors.size > 0
  puts "Errors : #{errors.size}"
#  puts errors.inspect
else
  puts 'No errors in reading!'
end
puts '======================================================================'
puts "Summary :: #{c} runs, #{n} keys"
puts '======================================================================'
puts '                  Minimum    Maximum      Total    Average        xps '
puts '----------------------------------------------------------------------'
summary.each do |sry|
  puts '%-14.14s % 10.4f % 10.4f % 10.4f % 10.4f % 10.4f ' % sry
end
