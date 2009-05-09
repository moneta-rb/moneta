begin
  require "rufus/tokyo"
rescue LoadError
  puts "You need the rufus gem to use the Rufus moneta store"
  exit
end

module Moneta
  class BasicRufus < ::Rufus::Tokyo::Cabinet    
    def initialize(options = {})
      file = options[:file]
      super("#{file}.tch")
    end
    
    def key?(key)
      !!self[key]
    end
    
    def [](key)
      if val = super
        Marshal.load(val)
      end
    end
    
    def []=(key, value)
      super(key, Marshal.dump(value))
    end
    
    def fetch(key, value = nil)
      value ||= block_given? ? yield(key) : default
      self[key] || value
    end
    
    def store(key, value, options = {})
      self[key] = value
    end
  end
  
  class Rufus < BasicRufus
    include Expires
    
    def initialize(options = {})
      file = options[:file]
      @expiration = BasicRufus.new(:file => "#{file}_expires")
      super
    end
  end
end