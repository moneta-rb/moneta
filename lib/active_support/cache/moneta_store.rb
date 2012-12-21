module ActiveSupport
  module Cache
    class MonetaStore < Store
      def initialize(options = nil)
        raise ArgumentError, 'Option :store is required' unless @store = options.delete(:store)
        @store = ::Moneta.new(@store, :expires => true) if Symbol === @store
        super(options)
        extend Strategy::LocalCache
      end

      def clear(options = nil)
        instrument(:clear, nil, nil) do
          @store.clear(options || {})
        end
      end

      protected

      def read_entry(key, options)
        @store.load(key, moneta_options(options))
      end

      def write_entry(key, entry, options)
        @store.store(key, entry, moneta_options(options))
        true
      end

      def delete_entry(key, options)
        @store.delete(key, moneta_options(options))
        true
      end

      private

      def moneta_options(options)
        options ||= {}
        options[:expires] = options.delete(:expires_in).to_i if options.include?(:expires_in)
        options
      end
    end
  end
end
