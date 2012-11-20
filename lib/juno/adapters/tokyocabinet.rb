require 'tokyocabinet'

module Juno
  module Adapters
    class TokyoCabinet < Memory
      def initialize(options = {})
        file = options[:file]
        raise 'No option :file specified' unless options[:file]
        @memory = ::TokyoCabinet::HDB.new
        unless @memory.open(file, ::TokyoCabinet::HDB::OWRITER | ::TokyoCabinet::HDB::OCREAT)
          raise @memory.errmsg(@memory.ecode)
        end
      end

      def key?(key, options = {})
        !!load(key, options)
      end

      def delete(key, options = {})
        value = load(key, options)
        if value
          @memory.delete(key)
          value
        end
      end

      def close
        @memory.close
        nil
      end
    end
  end
end
