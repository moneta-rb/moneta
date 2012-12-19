require 'moneta'
require 'fileutils'
require 'monetaspecs'

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
    puts "\e[31mTest #{name} not executed: #{ex.message}\e[0m"
  rescue Exception => ex
    puts "\e[31mTest #{name} not executed: #{ex.message}\e[0m"
    puts ex.backtrace.join("\n")
  end
end

shared_context 'setup_store' do
  let(:store) do
    new_store
  end

  before do
    store.clear
  end

  after do
    store.close.should == nil if store
  end
end
