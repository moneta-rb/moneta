module Moneta
  module Adapters
    # Null backend which doesn't store anything
    # @api public
    class Null < Base
      def initialize(options = {})
      end

      def key?(key, options = {})
        false
      end

      def load(key, options = {})
        nil
      end

      def store(key, value, options = {})
        value
      end

      def delete(key, options = {})
        nil
      end

      def clear(options = {})
        self
      end
    end
  end
end
