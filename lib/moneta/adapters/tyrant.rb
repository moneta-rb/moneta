begin
  require "tokyotyrant"
rescue LoadError
  puts "You need the tokyotyrant gem to use the Tyrant moneta store"
  exit
end

module Moneta
  module Adapters
    class Tyrant
      include Defaults

      def initialize(options = {})
        @hash = ::TokyoTyrant::RDB.new

        if !@hash.open(options[:host], options[:port])
          puts @hash.errmsg(@hash.ecode)
        end
      end

      def key?(key, *)
        !!self[key]
      end

      def [](key)
        deserialize(@hash[key_for(key)])
      end

      def store(key, value, *)
        @hash.put(key_for(key), serialize(value))
      end

      def clear(*)
        @hash.clear
      end

      def delete(key, *)
        if value = self[key]
          @hash.delete(key_for(key))
          value
        end
      end
    end
  end
end
