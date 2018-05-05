module Moneta
  module Adapters
    # ActiveSupport::Cache::Store adapter
    # @api public
    class ActiveSupportCache
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
        value = @backend.read(key)
        if options[:raw]
          value && value.to_s
        else
          value
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @backend.write(key, value)
        value
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        if existing = @backend.read(key)
          value = Integer(existing) + amount
          @backend.write(key, value)
          value
        else
          @backend.write(key, amount)
          amount
        end
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = @backend.read(key)
        if value != nil
          @backend.delete(key)
          options[:raw] ? value.to_s : value
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
