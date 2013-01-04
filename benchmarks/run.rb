#!/usr/bin/env ruby

$: << File.join(File.dirname(__FILE__), '..', 'lib')
require 'benchmark'
require 'moneta'

STORES = {
  # SDBM is unstable
  # :SDBM => { :file => 'bench.sdbm' },
  # YAML is so fucking slow
  # :YAML => { :file => 'bench.yaml' },
  :ActiveRecord => { :connection => { :adapter  => 'sqlite3', :database => ':memory:' } },
  :Cassandra => {},
  :Client => {},
  :Couch => {},
  :DBM => { :file => 'bench.dbm' },
  :DataMapper => { :setup => 'sqlite3:bench.datamapper' },
  :Daybreak => { :file => 'bench.daybreak' },
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
  :RestClient => { :url => 'http://localhost:8808/' },
  :Riak => {},
  :Sequel => { :db => 'sqlite:/' },
  :Sqlite => { :file => ':memory:' },
  :TDB => { :file => 'bench.tdb' },
}

CONFIGS = {
  :uniform_small => {
    :runs => 3,
    :keys => 1000,
    :min_key_length => 1,
    :max_key_length => 32,
    :key_dist => :uniform,
    :min_val_length => 0,
    :max_val_length => 256,
    :val_dist => :uniform
  },
  :uniform_medium => {
    :runs => 3,
    :keys => 100,
    :min_key_length => 3,
    :max_key_length => 200,
    :key_dist => :uniform,
    :min_val_length => 0,
    :max_val_length => 1024,
    :val_dist => :uniform
  },
  :uniform_large => {
    :runs => 3,
    :keys => 100,
    :min_key_length => 3,
    :max_key_length => 200,
    :key_dist => :uniform,
    :min_val_length => 0,
    :max_val_length => 10240,
    :val_dist => :uniform
  },
  :normal_small => {
    :runs => 3,
    :keys => 1000,
    :min_key_length => 1,
    :max_key_length => 32,
    :key_dist => :normal,
    :min_val_length => 0,
    :max_val_length => 256,
    :val_dist => :normal
  },
  :normal_medium => {
    :runs => 3,
    :keys => 100,
    :min_key_length => 3,
    :max_key_length => 200,
    :key_dist => :normal,
    :min_val_length => 0,
    :max_val_length => 1024,
    :val_dist => :normal
  },
  :normal_large => {
    :runs => 3,
    :keys => 100,
    :min_key_length => 3,
    :max_key_length => 200,
    :key_dist => :normal,
    :min_val_length => 0,
    :max_val_length => 10240,
    :val_dist => :normal
  },
}

config_name = ARGV.size == 1 ? ARGV.first.to_sym : :uniform_medium
unless config = CONFIGS[config_name]
  puts "Configuration #{config_name} not found"
  exit
end

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

Process.fork do
  require 'rack'
  require 'webrick'
  require 'rack/moneta_rest'

  # Keep webrick quiet
  ::WEBrick::HTTPServer.class_eval do
    def access_log(config, req, res); end
  end
  ::WEBrick::BasicLog.class_eval do
    def log(level, data); end
  end

  Rack::Server.start(:app => Rack::Builder.app do
                       use Rack::Lint
                       run Rack::MonetaRest.new(:store => :Memory)
                     end,
                     :environment => :none,
                     :server => :webrick,
                     :Port => 8808)
end

sleep 1 # Wait for servers

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

puts "\e[1m\e[36m#{SEPARATOR}\n\e[36mConfig #{config_name}\n\e[36m#{SEPARATOR}\e[0m"
config.each do |k,v|
  puts '%-16s = %-10s' % [k,v]
end

module Rand
  extend self

  def normal_rand(mean, stddev)
    # Box-Muller transform
    theta = 2 * Math::PI * (rand(1e10) / 1e10)
    scale = stddev * Math.sqrt(-2 * Math.log(1 - (rand(1e10) / 1e10)))
    [mean + scale * Math.cos(theta),
     mean + scale * Math.sin(theta)]
  end

  def uniform(min, max)
    rand(max - min) + min
  end

  def normal(min, max)
    mean = (min + max) / 2
    stddev = (max - min) / 4
    loop do
      val = normal_rand(mean, stddev)
      return val.first if val.first >= min && val.first <= max
      return val.last if val.last >= min && val.last <= max
    end
  end
end

stats, data, summary = {}, {}, []

until data.size == config[:keys]
  key = DICT.random(Rand.send(config[:key_dist], config[:min_key_length], config[:max_key_length]))
  data[key] = DICT.random(Rand.send(config[:val_dist], config[:min_val_length], config[:max_val_length]))
end

key_lengths, val_lengths = data.keys.map(&:size), data.values.map(&:size)
data = data.to_a

def write_histogram(file, sizes)
  min = sizes.min
  delta = sizes.max - min
  histogram = []
  sizes.each do |s|
    s = 10 * (s - min) / delta
    histogram[s] ||= 0
    histogram[s] += 1
  end
  File.open(file, 'w') do |f|
    histogram.each_with_index { |n,i| f.puts "#{i*delta/10+min} #{n}" }
  end
end

write_histogram('key.histogram', key_lengths)
write_histogram('value.histogram', val_lengths)

puts "\n\e[1m\e[34m#{SEPARATOR}\n\e[34mComputing keys and values...\n\e[34m#{SEPARATOR}\e[0m"
puts %{                         Minimum  Maximum    Total  Average}
puts 'Key Length              % 8d % 8d % 8d % 8d ' % [key_lengths.min, key_lengths.max, key_lengths.sum, key_lengths.sum / data.size]
puts 'Value Length            % 8d % 8d % 8d % 8d ' % [val_lengths.min, val_lengths.max, val_lengths.sum, val_lengths.sum / data.size]

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
      print "%s [%#{2 * config[:runs]}s] " % [type, state]

      config[:runs].times do |run|
        cache.clear
        print "%s[%-#{2 * config[:runs]}s] " % ["\b" * (2 * config[:runs] + 3), state << 'W']

        data = data.randomize
        m1 = Benchmark.measure do
          data.each {|k,v| cache[k] = v }
        end

        print "%s[%-#{2 * config[:runs]}s] " % ["\b" * (2 * config[:runs] + 3), state << 'R']

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
      ops = (config[:runs] * data.size) / total
      line = '%-17.17s %-5s % 8d % 8d % 8d % 8d % 8d' %
        [name, i, stats[name][i].min * 1000, stats[name][i].max * 1000,
         total * 1000, total * 1000 / config[:runs], ops]
      summary << [-ops, line << "\n"] if i == :sum
      puts line
    end

    errors = stats[name][:error].sum
    if errors > 0
      puts "\e[31m%-23.23s % 8d % 8d % 8d % 8d\e[0m" %
        ['Read errors', stats[name][:error].min, stats[name][:error].max, errors, errors / config[:runs]]
    else
      puts "\e[32mNo read errors"
    end
  rescue StandardError => ex
    puts "\n\e[31mFailed to benchmark #{name} - #{ex.message}\e[0m\n"
  ensure
    cache.close if cache
  end
end

puts "\n\e[1m\e[36m#{SEPARATOR}\n\e[36mSummary #{config_name}: #{config[:runs]} runs, #{data.size} keys\n\e[36m#{SEPARATOR}\e[0m#{HEADER}\n"
summary.sort_by(&:first).each do |entry|
  puts entry.last
end
