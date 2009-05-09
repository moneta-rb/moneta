#!/usr/bin/env ruby
require 'benchmark'
require "rubygems"

# Hacked arrays
# Array modifications
class HackedArray < Array
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

require "../lib/moneta"
require "moneta/memcache"
require "moneta/tyrant"
require "moneta/berkeley"


stores = {
  'Redis' => { },
  'Memcached' => { :class_name => "Memcache", :server => "localhost:11211", :namespace => 'moneta_bench' },
  'Tyrant' => { :host => 'localhost', :port => 1978 }, # Breaks for any n > 50 on my machine
  'MongoDB' => { :host => 'localhost', :port => 27017, :db => 'moneta_bench' },
  'LMC' => { :filename => "bench.lmc" },
  'Berkeley' => { :file => "bench.bdb" },
  'Rufus' => {:file => "bench.rufus"},
  'Memory' => { },
  'DataMapper' => { :setup => "sqlite3::memory:" },
  # 'Couch' => {:db => "couch_test"},
  'TC (Tyrant)' => 
    {:name => "test.tieredtyrant", :backup => Moneta::Tyrant.new(:host => "localhost", :port => 1978), :class_name => "TieredCache"},
  'TC (Memcached)' => 
    {:name => "test.tieredmc", :backup => Moneta::Memcache.new(:server => "localhost:11211", :namespace => "various"), :class_name => "TieredCache"}
}

stats, keys, data, errors, summary = {}, [], HackedArray.new, HackedArray.new, HackedArray.new
dict = HackedArray.new_from_string 'abcdefghijklnopq123456789'
n = ARGV[0] ? ARGV[0].to_i : 100
m = ARGV[1] ? ARGV[1].to_i : 10
c = ARGV[2] ? ARGV[2].to_i : 3
vlen_min, vlen_max, vlen_ttl, vlen_avg = 99999, 0, 0, 0
ds = dict.size

puts "======================================================================"
puts "Comparison of write/read between Moneta Stores"
puts "======================================================================"

puts "Data loading..."
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

puts "----------------------------------------------------------------------"
#puts data.inspect
puts "Total keys: #{keys.size}, unique: #{keys.uniq.size}"
#puts keys.sort.inspect

puts "----------------------------------------------------------------------"
puts "                  Minimum    Maximum      Total    Average        xps "
puts "----------------------------------------------------------------------"
puts "Lenght Stats   % 10i % 10i % 10i % 10i " % [vlen_min, vlen_max, vlen_ttl, vlen_avg]

module Moneta
  class TieredCache
    include Moneta::Defaults
  
    def initialize(options)
      @bdb = Moneta::Berkeley.new(:file => File.join(File.dirname(__FILE__), options[:name]))
      @mc = options[:backup]
      # @mc = Moneta::Tyrant.new(:host => "localhost", :port => 1978)
      # @mc  = Moneta::Memcache.new(:server => "localhost:11211", :namespace => options[:name])
    end
  
    def [](key)
      val = @bdb[key]
      unless val
        @bdb[key] = val if val = @mc[key]
      end
      val
    end
  
    def []=(key, val)
      @bdb[key] = val
      @mc[key]  = val
    end
  
    def store(key, value, options = {})
      @bdb.store(key, value, options)
      @mc.store(key, value, options)
    end
  
    def delete(key)
      bdb_val = @bdb.delete(key)
      mc_val  = @mc.delete(key)
      bdb_val || mc_val
    end
  
    def clear
      @mc.clear
      @bdb.clear
    end
  
    def update_key(name, options)
      @mc.update_key(name, options)
      @bdb.update_key(name, options)
    end
  
    def key?(key)
      @bdb.key?(key) || @mc.key?(key)
    end
  end
end

stores.each do |name, options|
  cname = options.delete(:class_name) || name
  puts "======================================================================"
  puts name
  puts "----------------------------------------------------------------------"
  begin
    require "../lib/moneta/#{cname.downcase}"
  rescue LoadError
  end
  klass = Moneta.const_get(cname)
  @cache = klass.new(options)
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
    print "W "
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
  print "\n"
  puts "----------------------------------------------------------------------"
  puts "                  Minimum    Maximum      Total    Average        xps "
  puts "----------------------------------------------------------------------"
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
    puts "%-14.14s % 10.4f % 10.4f % 10.4f % 10.4f % 10.4f " % ["#{name} #{sname}", cmin, cmax, ctot, cavg, n / cavg]
  end
  tcavg = tctot / (c * 2)
  puts "%-14.14s % 10.4f % 10.4f % 10.4f % 10.4f % 10.4f " % ["#{name} avgs", tcmin, tcmax, tctot, tcavg, n / tcavg]
  summary << [name, tcmin, tcmax, tctot, tcavg, n / tcavg]
end
puts "----------------------------------------------------------------------"
if errors.size > 0
  puts "Errors : #{errors.size}"
#  puts errors.inspect
else
  puts "No errors in reading!"
end
puts "======================================================================"
puts "Summary :: #{c} runs, #{n} keys"
puts "======================================================================"
puts "                  Minimum    Maximum      Total    Average        xps "
puts "----------------------------------------------------------------------"
summary.each do |sry|
  puts "%-14.14s % 10.4f % 10.4f % 10.4f % 10.4f % 10.4f " % sry
end
puts "======================================================================"
puts "THE END"
puts "======================================================================"

#======================================================================
#Summary :: 3 runs, 1000 keys
#======================================================================
#                  Minimum    Maximum      Total    Average       xps
#----------------------------------------------------------------------
#MemcacheDB         0.6202     2.7850     7.0099     1.1683   855.9366
#Memcached          0.4483     0.6563     3.3251     0.5542  1804.4385
#Redis              0.3282     0.5221     2.2965     0.3828  2612.6444
#MongoDB            0.6660     1.0539     5.1667     0.8611  1161.2745
#======================================================================
