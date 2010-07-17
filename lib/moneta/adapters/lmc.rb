begin
  require "localmemcache"
rescue LoadError
  puts "You need the localmemcache gem to use the LMC moneta store"
  exit
end

module Moneta
  module Adapters
    class LMC
      include Defaults

      def initialize(options = {})
        @hash = LocalMemCache.new(:filename => options[:filename])
      end

      def [](key)
        deserialize(@hash[key_for(key)])
      end

      def store(key, value, *) 
        @hash[key_for(key)] = serialize(value)
      end

      def clear(*)
        @hash.clear
      end

      def key?(key, *)
        @hash.keys.include?(key_for(key))
      end

      def delete(key, *)
        value = self[key]
        @hash.delete(key_for(key))
        value
      end
    end
  end
end
