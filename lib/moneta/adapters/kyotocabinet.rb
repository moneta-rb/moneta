require 'kyotocabinet'

module Moneta
  module Adapters
    # KyotoCabinet backend
    # @api public
    class KyotoCabinet < Memory
      # @param [Hash] options
      # @option options [String] :file Database file
      # @option options [::KyotoCabinet::DB] :backend Use existing backend instance
      def initialize(options = {})
        if options[:backend]
          @backend = options[:backend]
        else
          raise ArgumentError, 'Option :file is required' unless options[:file]
          @backend = ::KyotoCabinet::DB.new
          raise @backend.error.to_s unless @backend.open(options[:file],
                                                         ::KyotoCabinet::DB::OWRITER | ::KyotoCabinet::DB::OCREATE)
        end
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @backend.check(key) >= 0
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        @backend.seize(key)
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        @backend.add(key, value)
      end

      # (see Proxy#close)
      def close
        @backend.close
        nil
      end
    end
  end
end
