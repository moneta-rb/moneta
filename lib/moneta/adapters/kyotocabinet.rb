require 'kyotocabinet'

module Moneta
  module Adapters
    # KyotoCabinet backend
    # @api public
    class KyotoCabinet < Memory
      # @param [Hash] options
      # @option options [String] :file Database file
      def initialize(options = {})
        raise ArgumentError, 'Option :file is required' unless options[:file]
        @hash = ::KyotoCabinet::DB.new
        raise @hash.error.to_s unless @hash.open(options[:file],
                                                 ::KyotoCabinet::DB::OWRITER | ::KyotoCabinet::DB::OCREATE)
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @hash.check(key) >= 0
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        @hash.seize(key)
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        @hash.add(key, value)
      end

      # (see Proxy#close)
      def close
        @hash.close
        nil
      end
    end
  end
end
