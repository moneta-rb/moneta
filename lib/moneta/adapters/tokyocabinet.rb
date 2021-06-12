require 'tokyocabinet'

module Moneta
  module Adapters
    # TokyoCabinet backend
    # @api public
    class TokyoCabinet < Adapter
      include HashAdapter
      include IncrementSupport
      include CreateSupport
      include EachKeySupport

      # @!method initialize(options = {})
      #   @param [Hash] options
      #   @option options [String] :file Database file
      #   @option options [Symbol] :type (:hdb) Database type (:bdb and :hdb possible)
      #   @option options [::TokyoCabinet::*DB] :backend Use existing backend instance
      backend do |file:, type: :hdb|
        case type
        when :bdb
          ::TokyoCabinet::BDB.new.tap do |backend|
            backend.open(file, ::TokyoCabinet::BDB::OWRITER | ::TokyoCabinet::BDB::OCREAT) or
              raise backend.errmsg(backend.ecode)
          end
        when :hdb
          ::TokyoCabinet::HDB.new.tap do |backend|
            backend.open(file, ::TokyoCabinet::HDB::OWRITER | ::TokyoCabinet::HDB::OCREAT) or
              raise backend.errmsg(backend.ecode)
          end
        else
          raise ArgumentError, ":type must be :bdb or :hdb"
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
