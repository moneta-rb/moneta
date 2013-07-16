require 'tokyocabinet'

module Moneta
  module Adapters
    # TokyoCabinet backend
    # @api public
    class TokyoCabinet < Memory
      # @param [Hash] options
      # @option options [String] :file Database file
      # @option options [Symbol] :type (:hdb) Database type (:bdb and :hdb possible)
      # @option options [::TokyoCabinet::*DB] :backend Use existing backend instance
      def initialize(options = {})
        if options[:backend]
          @backend = options[:backend]
        else
          raise ArgumentError, 'Option :file is required' unless options[:file]
          if options[:type] == :bdb
            @backend = ::TokyoCabinet::BDB.new
            @backend.open(options[:file], ::TokyoCabinet::BDB::OWRITER | ::TokyoCabinet::BDB::OCREAT)
          else
            @backend = ::TokyoCabinet::HDB.new
            @backend.open(options[:file], ::TokyoCabinet::HDB::OWRITER | ::TokyoCabinet::HDB::OCREAT)
          end or raise @backend.errmsg(@backend.ecode)
        end
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = load(key, options)
        if value
          @backend.delete(key)
          value
        end
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        @backend.putkeep(key, value)
      end

      # (see Proxy#close)
      def close
        @backend.close
        nil
      end
    end
  end
end
