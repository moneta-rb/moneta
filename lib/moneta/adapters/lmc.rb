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

      def [](key)         @hash[Marshal.dump(key)]          end
      def []=(key, value) @hash[Marshal.dump(key)] = value  end
      def clear()         @hash.clear                       end

      def key?(key)
        @hash.keys.include?(Marshal.dump(key))
      end

      def delete(key)
        value = self[key]
        @hash.delete(Marshal.dump(key))
        value
      end
    end
  end
end