require 'rspec'
require 'rspec/core/formatters/base_text_formatter'
require 'rspec/retry'
require 'moneta'
require 'fileutils'
require 'monetaspecs'

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

RSpec.configure do |config|
  config.verbose_retry = true
  config.color_enabled = true
  config.tty = true
  config.formatter = ENV['PARALLEL_TESTS'] ? MonetaParallelFormatter : :progress
end

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

def make_tempdir
  # Expand path since datamapper needs absolute path in setup
  tempdir = File.expand_path(File.join(File.dirname(__FILE__), 'tmp'))
  FileUtils.mkpath(tempdir)
  tempdir
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

class InitializeStore
  def initialize(&block)
    instance_eval(&block)
    store = new_store
    store['foo'] = 'bar'
    store.clear
    store.close
  end

  def method_missing(*args)
  end
end

def describe_moneta(name, &block)
  begin
    InitializeStore.new(&block)
    describe(name, &block)
  rescue LoadError => ex
    puts "\e[31mTest #{name} not executed: #{ex.class} - #{ex.message}\e[0m"
  rescue Exception => ex
    puts "\e[31mTest #{name} not executed: #{ex.class} - #{ex.message}\e[0m"
    puts ex.backtrace.join("\n")
  end
end

shared_context 'setup_store' do
  def store
    @store ||= new_store
  end

  before do
    store.clear
  end

  after do
    if store
      store.close.should == nil
      @store = nil
    end
  end
end
