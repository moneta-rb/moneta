require 'daybreak'

module Moneta
  module Adapters
    # Daybreak backend
    # @api public
    class Daybreak < Memory
      class Serializer < ::Daybreak::Serializer
        def key_for(key) key; end
        def dump(value) value; end
        def load(value) value; end
      end

      # @param [Hash] options
      # @option options [String] :file Database file
      def initialize(options = {})
        raise ArgumentError, 'Option :file is required' unless options[:file]
        @hash = ::Daybreak::DB.new(options[:file], :serializer => Serializer)
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @hash.lock { return super }
      end

      # (see Proxy#close)
      def close
        @hash.close
      end
    end
  end
end
