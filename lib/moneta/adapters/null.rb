module Moneta
  module Adapters
    # Null backend which doesn't store anything
    # @api public
    class Null
      include Defaults

      def initialize(options = {})
      end

      # @see Proxy#key?
      def key?(key, options = {})
        false
      end

      # @see Proxy#load
      def load(key, options = {})
        nil
      end

      # @see Proxy#store
      def store(key, value, options = {})
        value
      end

      # @see Proxy#delete
      def delete(key, options = {})
        nil
      end

      # @see Proxy#clear
      def clear(options = {})
        self
      end
    end
  end
end
