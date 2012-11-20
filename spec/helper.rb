require 'juno'
require 'fileutils'
require 'junospecs'

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
