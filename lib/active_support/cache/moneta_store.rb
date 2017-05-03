module ActiveSupport
  module Cache
    # @api public
    class MonetaStore < Store
      def initialize(options = nil)
        raise ArgumentError, 'Option :store is required' unless @store = options.delete(:store)
        @store = ::Moneta.new(@store, expires: true) if Symbol === @store
        super(options)
        extend Strategy::LocalCache
      end

      def increment(key, amount = 1, options = nil)
        options = merged_options(options)
        instrument(:increment, key, amount: amount) do
          @store.increment(namespaced_key(key, options), amount, moneta_options(options))
        end
      end

      def decrement(key, amount = 1, options = nil)
        options = merged_options(options)
        instrument(:decrement, key, amount: amount) do
          @store.increment(namespaced_key(key, options), -amount, moneta_options(options))
        end
      end

      def clear(options = nil)
        options = merged_options(options)
        instrument(:clear, nil, nil) do
          @store.clear(moneta_options(options))
        end
      end

      protected

      def read_entry(key, options)
        options.delete(:expires_in)
        entry = @store.load(key, moneta_options(options))
        entry && (ActiveSupport::Cache::Entry === entry ? entry : ActiveSupport::Cache::Entry.new(entry))
      end

      def write_entry(key, entry, options)
        value = options[:raw] ? entry.value.to_s : entry
        @store.store(key, value, moneta_options(options))
        true
      end

      def delete_entry(key, options)
        @store.delete(key, moneta_options(options))
        true
      end

      private

      def moneta_options(options)
        new_options = options ? options.dup : {}
        new_options[:expires] = new_options.delete(:expires_in).to_i if new_options.include?(:expires_in)
        new_options
      end
    end
  end
end
