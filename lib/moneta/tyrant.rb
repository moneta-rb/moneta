begin
  require "rufus/tokyo"
rescue LoadError
  puts "You need the rufus gem to use the Tyrant moneta store"
  exit
end

module Moneta
  class Tyrant < ::Rufus::Tokyo::Tyrant
    module Implementation
      def initialize(options = {})
        host = options[:host]
        port = options[:port]
        super(host, port)
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
    
      def fetch(key, default)
        self[key] || default
      end
    
      def store(key, value, options = {})
        self[key] = value
      end
    end
    include Implementation
    include Expires
    
    def initialize(options = {})
      super
      @expiration = Expiration.new(options)
    end
    
    class Expiration < ::Rufus::Tokyo::Tyrant
      include Implementation
      
      def [](key)
        super("#{key}__expiration")
      end
      
      def []=(key, value)
        super("#{key}__expiration", value)
      end
      
      def delete(key)
        super("#{key}__expiration")
      end
    end
  end  
end