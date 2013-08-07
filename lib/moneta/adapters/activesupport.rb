module Moneta
  module Adapters
    # ActiveSupport::Cache::Store adapter
    # @api public
    class ActiveSupport
      include Defaults

      supports :increment

      # @param [Hash] options
      def initialize(options = {})
        @backend =
          if options[:backend]
            options[:backend]
          elsif defined?(Rails)
            Rails.cache
          else
            raise ArgumentError, 'Option :backend is required'
          end
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @backend.exist?(key)
      end

      # (see Proxy#load)
      def load(key, options = {})
        @backend.read(key)
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @backend.write(key, value)
        value
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        if amount >= 0
          result = @backend.increment(key, amount)
          if result == nil
            @backend.write(key, amount)
            amount
          else
            result
          end
        else
          result = @backend.decrement(key, amount)
          if result == nil
            @backend.write(key, -amount)
            -amount
          else
            result
          end
        end
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = @backend.read(key)
        if value != nil
          @backend.delete(key)
          value
        end
      end

      # (see Proxy#clear)
      def clear(options = {})
        @backend.clear
        self
      end
    end
  end
end
