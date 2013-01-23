require 'daybreak'

module Moneta
  module Adapters
    # Daybreak backend
    # @api public
    class Daybreak < Memory
      # @param [Hash] options
      # @option options [String] :file Database file
      def initialize(options = {})
        raise ArgumentError, 'Option :file is required' unless options[:file]
        @hash = ::Daybreak::DB.new(options[:file], :serializer => ::Daybreak::Serializer::None)
      end

      # (see Proxy#load)
      def load(key, options = {})
        @hash.load if options[:sync]
        @hash[key]
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @hash[key] = value
        @hash.flush if options[:sync]
        value
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @hash.lock { super }
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        @hash.lock { super }
      end

      # (see Proxy#close)
      def close
        @hash.close
      end
    end
  end
end
