module ActiveSupport
  module Cache
    class MonetaStore < Store
      def initialize(options = nil)
        super(options)
        @store = options[:store]
        extend Strategy::LocalCache
      end

      def clear(options = nil)
        @store.clear(options || {})
      end

      def increment(key, amount = 1, options = nil)
        @store[key] += amount
      end

      def decrement(key, amount = 1, options = nil)
        @store[key] -= amount
      end

      protected

      def read_entry(key, options)
        @store.load(key, options || {})
      end

      def write_entry(key, entry, options)
        @store.store(key, entry, options || {})
        true
      end

      def delete_entry(key, options)
        @store.delete(key, options || {})
        true
      end
    end
  end
end
