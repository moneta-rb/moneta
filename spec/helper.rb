require 'rspec/core/formatters/base_text_formatter'
require 'moneta'
require 'fileutils'
require 'tmpdir'

ENV['RANTLY_VERBOSE'] ||= '0'

require 'rspec/retry'
require 'rantly'
require 'rantly/rspec_extensions'
# rantly/shrinks
require 'timecop'

class MonetaParallelFormatter < RSpec::Core::Formatters::BaseTextFormatter
  def start(*args)

    output.puts colorise_summary("STARTING #{ARGV.join(' ')}")
    @stopped = false
    @passed_count = 0
    @heartbeat = Thread.new do
      count = 0
      until @stopped
        if (count += 1) % 60 == 0
          output.puts(color("RUNNING  #{ARGV.join(' ')} - #{@passed_count} passed, #{failed_examples.size} failures",
                            failed_examples.empty? ? RSpec.configuration.success_color : RSpec.configuration.failure_color))
        end
        sleep 0.5
      end
    end
  end

  def example_passed(example)
    super
    @passed_count += 1
  end

  def stop
    @stopped = true
    @heartbeat.join
  end

  def dump_summary(duration, example_count, failure_count, pending_count)
    @duration = duration
    @example_count = example_count
    @failure_count = failure_count
    @pending_count = pending_count
    output.puts colorise_summary(summary_line(example_count, failure_count, pending_count))
    dump_commands_to_rerun_failed_examples
  end

  def summary_line(example_count, failure_count, pending_count)
    "FINISHED #{ARGV.join(' ')} in #{format_duration(duration)} - #{super}"
  end
end

class MonetaSpecs
  KEYS = {
    'nil' => [:choose, nil, 0],
    'integer' => :integer,
    'float' => :float,
    'boolean' => :boolean,
    'string' => proc{ sized(range 5, 10){ string(:alnum) } },
    'path' => proc{ array(range 2, 3){ sized(range 5, 10){ string(:alpha) } }.join('/') },
    'binary' => [:string, :cntrl],
    'object' => proc{ choose Value.new(:objkey1), Value.new(:objkey2) },
    'hash' => proc{ dict(2){ sized(range 5, 10){ [string(:alnum), string(:alnum)] } } }
  }

  VALUES = {
    'nil' => [:literal, nil],
    'integer' => :integer,
    'float' => :float,
    'boolean' => :boolean,
    'string' => [:string, :alnum],
    'binary' => [:string, :cntrl],
    'object' => proc{ choose Value.new(:objval1), Value.new(:objval2) },
    'hash' => proc{ dict{ [string(:alnum), array(2){ choose(string(:alnum), integer, dict{ [string(:alnum), integer] }) }] } },
    'smallhash' => proc{ dict(2){ sized(range 5, 10){ [string(:alnum), string(:alnum)] } } }
  }

  attr_reader :key, :value, :specs, :features

  def initialize(options = {})
    @specs = options.delete(:specs).to_a
    @features = @specs & [:expires, :expires_native, :increment, :each_key, :create]
    @key = options.delete(:key)     || %w(object string binary hash boolean nil integer float)
    @value = options.delete(:value) || %w(object string binary hash boolean nil integer float)
  end

  def new(options)
    self.class.new({specs: specs, key: key, value: value}.merge(options))
  end

  def with_keys(*keys)
    new(key: self.key | keys.map(&:to_s))
  end

  def without_keys(*keys)
    new(key: self.key - keys.map(&:to_s))
  end

  def with_values(*values)
    new(value: self.value | values.map(&:to_s))
  end

  def without_values(*values)
    new(value: self.value - values.map(&:to_s))
  end

  def without_keys_or_values(*types)
    without_keys(*types).without_values(*types)
  end

  def without_path
    new(key: key - %w(path))
  end

  def stringvalues_only
    new(value: %w(string))
  end

  def simplekeys_only
    new(key: %w(string hash integer))
  end

  def simplevalues_only
    new(value: %w(string hash integer))
  end

  def without_increment
    new(specs: specs - [:increment, :concurrent_increment] + [:not_increment])
  end

  def without_large
    new(specs: specs - [:store_large]).instance_exec do
      if value.include? 'hash'
        without_values(:hash).with_values(:smallhash)
      else
        self
      end
    end
  end

  def without_concurrent
    new(specs: specs - [:concurrent_increment, :concurrent_create])
  end

  def without_persist
    new(specs: specs - [:persist, :multiprocess, :concurrent_increment, :concurrent_create] + [:not_persist])
  end

  def without_multiprocess
    new(specs: specs - [:multiprocess, :concurrent_increment, :concurrent_create])
  end

  def with_expires
    a = specs.dup
    if a.include?(:transform_value)
      a.delete(:transform_value)
      a << :transform_value_expires
    end
    a << :create_expires if a.include?(:create)
    a << :expires
    new(specs: a)
  end

  def with_native_expires
    a = specs.dup
    a << :create_expires if a.include?(:create)
    new(specs: a + [:expires])
  end

  def without_marshallable
    new(specs: specs - [:marshallable_value, :marshallable_key])
  end

  def without_transform
    new(specs: specs - [:marshallable_value, :marshallable_key, :transform_value])
  end

  def returnsame
    new(specs: specs - [:returndifferent] + [:returnsame])
  end

  def without_marshallable_key
    new(specs: specs - [:marshallable_key])
  end

  def without_marshallable_value
    new(specs: specs - [:marshallable_value])
  end

  def without_store
    new(specs: specs - [:store, :store_large, :transform_value, :marshallable_value])
  end

  def with_default_expires
    new(specs: specs + [:default_expires])
  end

  def with_each_key
    new(specs: specs - [:not_each_key] | [:each_key])
  end

  def without_create
    new(specs: specs - [:create, :concurrent_create, :create_expires] + [:not_create])
  end
end

ADAPTER_SPECS = MonetaSpecs.new(
  specs: [:null, :store, :returndifferent,
    :increment, :concurrent_increment, :concurrent_create, :persist, :multiprocess,
    :create, :features, :store_large, :not_each_key],
  key: %w(string path),
  value: %w(string path binary))
STANDARD_SPECS = MonetaSpecs.new(
  specs: [:null, :store, :returndifferent,
    :marshallable_key, :marshallable_value, :transform_value, :increment,
    :concurrent_increment, :concurrent_create, :persist, :multiprocess, :create,
    :features, :store_large, :not_each_key])
TRANSFORMER_SPECS = MonetaSpecs.new(
  specs: [:null, :store, :returndifferent,
    :transform_value, :increment, :create, :features, :store_large,
    :not_each_key])

module MonetaHelpers
  module ClassMethods

    def moneta_store store_name, options={}, &block
      name = self.description
      builder = proc do
        if block
          options = instance_exec(&block)
        end

        Moneta.new(store_name, options.merge(logger: {file: File.join(tempdir, "#{name}.log")}))
      end

      include_context :setup_moneta_store, builder
    end

    def moneta_build &block
      include_context :setup_moneta_store, block
    end

    def moneta_loader &block
      before do
        @moneta_value_loader = block
      end
    end

    def moneta_specs specs
      let(:features){ specs.features }
      let(:keys_meta) do
        [:branch, *specs.key.map{ |k| MonetaSpecs::KEYS[k] }.compact]
      end
      let(:values_meta) do
        [:branch, *specs.value.map{ |k| MonetaSpecs::VALUES[k] }.compact]
      end

      # Used by tests that rely on MySQL.  These env vars can be used if you
      # want to run the tests but don't want to grant root access to moneta
      let(:mysql_username) { ENV['MONETA_MYSQL_USERNAME'] || 'root' }
      let(:mysql_password) { ENV['MONETA_MYSQL_PASSWORD'] }
      let(:mysql_database1) { ENV['MONETA_MYSQL_DATABSASE1'] || 'moneta' }
      let(:mysql_database2) { ENV['MONETA_MYSQL_DATABSASE2'] || 'moneta2' }

      let(:postgres_username) { ENV['MONETA_POSTGRES_USERNAME'] || 'postgres' }
      let(:postgres_database1) { ENV['MONETA_POSTGRES_DATABSASE1'] || 'moneta1' }
      let(:postgres_database2) { ENV['MONETA_POSTGRES_DATABSASE1'] || 'moneta2' }

      before do
        store = new_store
        store.clear
        store.close
      end

      specs.specs.sort.each do |s|
        context "#{s} feature" do
          include_examples(s)
        end
      end
    end

    # Used to test time-dependent specs (e.g. expiry at different positions
    # within a second). Once close to the start of the second, and once close
    # to the end.
    def usecs
      [1e4, 99e4].map(&:to_i)
    end

    def at_each_usec(&block)
      usecs.each do |usec|
        context "at #{usec} microseconds", isolate: true do
          include_examples :at_usec, usec, &block
        end
      end
    end

    def use_timecop
      before{ @timecop = true }
    end

    def start_memcached(port)
      before :context do
        @memcached = spawn("memcached -p #{port}")
        sleep 0.5
      end

      after :context do
        Process.kill("TERM", @memcached)
        Process.wait(@memcached)
        @memcached = nil
      end
    end
  end

  module InstanceMethods
    def tempdir
      @moneta_tempdir ||= Dir.mktmpdir
    end

    def new_store
      instance_eval(&@moneta_store_builder)
    end

    def store
      @store ||= new_store
    end

    def load_value value
      if @moneta_value_loader
        @moneta_value_loader.call value
      else
        Marshal.load(value)
      end
    end

    def start_restserver
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

      Thread.start do
        Rack::Server.start(:app => Rack::Builder.app do
                             use Rack::Lint
                             map '/moneta' do
                               run Rack::MonetaRest.new(:store => :Memory)
                             end
                           end,
                           :environment => :none,
                           :server => :webrick,
                           :Port => 8808)
      end
      sleep 1
    end

    def start_server(*args)
      server = Moneta::Server.new(*args)
      Thread.new { server.run }
      sleep 0.1 until server.running?
    rescue Exception => ex
      puts "Failed to start server - #{ex.message}"
    end

    def moneta_property_of(keys: 0, values: 0)
      keys_meta = self.keys_meta
      values_meta = self.values_meta
      property_of do
        key_values = keys.times.map { call(keys_meta) }
        guard key_values.uniq.length == key_values.length

        value_values = values.times.map { call(values_meta) }
        guard value_values.uniq.length == value_values.length

        [[:keys, key_values], [:values, value_values]].
          reject { |key, value| value.empty? }.
          to_h
      end
    end

    def advance(seconds)
      return if seconds < 0
      if @timecop
        Timecop.freeze(Time.now + seconds)
      else
        sleep seconds
      end
    end
  end
end

RSpec.configure do |config|
  config.verbose_retry = true
  config.color = true
  #config.tty = true
  #config.formatter = ENV['PARALLEL_TESTS'] ? MonetaParallelFormatter : :progress
  config.silence_filter_announcements = true if ENV['PARALLEL_TESTS']

  # Allow "should" syntax as well as "expect"
  config.expect_with(:rspec) { |c| c.syntax = [:should, :expect] }

  config.extend MonetaHelpers::ClassMethods
  config.include MonetaHelpers::InstanceMethods
end

# FIXME: Get rid of this once raise_error expectations no longer generate
# warnings
RSpec::Expectations.configuration.on_potential_false_positives = :nothing

# Disable jruby stdout pollution by memcached
if defined?(JRUBY_VERSION)
  require 'java'
  properties = java.lang.System.getProperties();
  properties.put('net.spy.log.LoggerImpl', 'net.spy.memcached.compat.log.SunLogger');
  java.lang.System.setProperties(properties);
  java.util.logging.Logger.getLogger('').setLevel(java.util.logging.Level::OFF)
end

class Value
  attr_accessor :x
  def initialize(x)
    @x = x
  end

  def ==(other)
    Value === other && other.x == x
  end

  def eql?(other)
    Value === other && other.x == x
  end

  def hash
    x.hash
  end
end


def marshal_error
  # HACK: Marshalling structs in rubinius without class name throws
  # NoMethodError (to_sym). TODO: Create an issue for rubinius!
  if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
    RUBY_VERSION < '1.9' ? ArgumentError : NoMethodError
  else
    TypeError
  end
end


RSpec.shared_context :setup_moneta_store do |builder|
  before do
    @moneta_store_builder = builder
  end

  after do
    if @store
      @store.close.should == nil
      @store = nil
    end
  end

  after :all do
    if @moneta_tempdir
      FileUtils.remove_dir(@moneta_tempdir)
    end
  end
end

RSpec.shared_examples :at_usec do |usec|
  before do
    now = Time.now
    # 1000us is a rough guess at how many microseconds this code will take to run
    if now.usec + 1000 > usec
      advance(1 - 1e-6 * (now.usec - usec))
    else
      advance(1e-6 * (usec - now.usec))
    end
  end

  after do
    Timecop.return if @timecop
  end
end

Dir['./spec/features/*.rb'].each{ |rb| require rb }
