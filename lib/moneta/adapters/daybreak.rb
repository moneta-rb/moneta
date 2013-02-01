require 'daybreak'

module Moneta
  module Adapters
    # Daybreak backend
    # @api public
    class Daybreak < Memory
      # @param [Hash] options
      # @option options [String] :file Database file
      # @option options [::Daybreak] :backend Use existing backend instance
      def initialize(options = {})
        @backend = options[:backend] ||
          begin
            raise ArgumentError, 'Option :file is required' unless options[:file]
            ::Daybreak::DB.new(options[:file], :serializer => ::Daybreak::Serializer::None)
          end
      end

      # (see Proxy#load)
      def load(key, options = {})
        @backend.load if options[:sync]
        @backend[key]
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @backend[key] = value
        @backend.flush if options[:sync]
        value
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @backend.lock { super }
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        @backend.lock { super }
      end

      # (see Proxy#close)
      def close
        @backend.close
      end
    end
  end
end
