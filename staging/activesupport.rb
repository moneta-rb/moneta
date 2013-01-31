module Moneta
  module Adapters
    # ActiveSupport::Cache::Store adapter
    # @api public
    class ActiveSupport
      include Defaults

      supports :increment

      # @param [Hash] options
      def initialize(options = {})
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @store.exist?(key)
      end

      # (see Proxy#load)
      def load(key, options = {})
        @store.read(key)
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @store.write(key, value)
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        if amount >= 0
          @store.increment(key, amount)
        else
          @store.decrement(key, amount)
        end
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        @store.delete(key)
      end

      # (see Proxy#clear)
      def clear(options = {})
        @store.clear
      end
    end
  end
end
