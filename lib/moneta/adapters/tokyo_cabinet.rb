begin
  require "tokyocabinet"
rescue LoadError
  puts "You need the tokyocabinet gem to use the tokyo cabinet store"
  exit
end

module Moneta
  module Adapters
    class TokyoCabinet
      include Defaults

      def initialize(options = {})
        file = options[:file]
        @cache = ::TokyoCabinet::HDB.new
        unless @cache.open(file, ::TokyoCabinet::HDB::OWRITER | ::TokyoCabinet::HDB::OCREAT)
          puts @cache.errmsg(@cache.ecode)
        end
      end

      def [](key)
        deserialize(@cache[key_for(key)])
      end

      def store(key, value, *)
        @cache[key_for(key)] = serialize(value)
      end

      def key?(key, *)
        !!self[key]
      end

      def delete(key, *)
        value = self[key]

        if value
          @cache.delete(key_for(key))
          value
        end
      end

      def clear(*)
        @cache.clear
      end

      def close
        @cache.close
      end
    end
  end
end
