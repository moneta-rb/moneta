require 'tokyocabinet'

module Moneta
  module Adapters
    # TokyoCabinet backend
    # @api public
    class TokyoCabinet < Memory
      # @param [Hash] options
      # @option options [String] :file Database file
      # @option options [Symbol] :type (:hdb) Database type (:bdb and :hdb possible)
      def initialize(options = {})
        file = options[:file]
        raise ArgumentError, 'Option :file is required' unless options[:file]
        if options[:type] == :bdb
          @hash = ::TokyoCabinet::BDB.new
          @hash.open(file, ::TokyoCabinet::BDB::OWRITER | ::TokyoCabinet::BDB::OCREAT)
        else
          @hash = ::TokyoCabinet::HDB.new
          @hash.open(file, ::TokyoCabinet::HDB::OWRITER | ::TokyoCabinet::HDB::OCREAT)
        end or raise @hash.errmsg(@hash.ecode)
      end

      # @see Proxy#delete
      def delete(key, options = {})
        value = load(key, options)
        if value
          @hash.delete(key)
          value
        end
      end

      # @see Proxy#close
      def close
        @hash.close
        nil
      end
    end
  end
end
