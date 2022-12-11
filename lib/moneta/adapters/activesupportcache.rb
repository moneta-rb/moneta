module Moneta
  module Adapters
    # ActiveSupport::Cache::Store adapter
    # @api public
    class ActiveSupportCache < Adapter
      include ExpiresSupport

      supports :increment

      # @!method initialize(options = {})
      #   @param [Hash] options
      #   @option options [ActiveSupport::Cache::Store] :backend (Rails.cache) Cache store to use
      #   @option options [Numeric] :expires default expiration in seconds
      backend { Rails.cache if defined?(Rails) }

      # (see Proxy#key?)
      def key?(key, options = {})
        exists =
          begin
            backend_exist?(key)
          rescue ArgumentError, TypeError
            # these errors happen when certain adapters try to deserialize
            # values, which means there's something present
            true
          end

        if exists && (expires = expires_value(options, nil)) != nil
          value = backend_read(key, **options)
          backend_write(key, value, expires_in: expires ? expires.seconds : nil, **options)
        end

        exists
      end

      # (see Proxy#load)
      def load(key, options = {})
        expires = expires_value(options, nil)
        value = backend_read(key, **options)
        if value and expires != nil
          backend_write(key, value, expires_in: expires ? expires.seconds : nil, **options)
        end
        value
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        expires = expires_value(options)
        backend_write(key, value, expires_in: expires ? expires.seconds : nil, **options)
        value
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        expires = expires_value(options)
        options.delete(:raw)
        existing = Integer(backend_fetch(key, raw: true, **options) { 0 })
        if amount > 0
          backend_increment(key, amount, expires_in: expires ? expires.seconds : nil, **options)
        elsif amount < 0
          backend_decrement(key, -amount, expires_in: expires ? expires.seconds : nil, **options)
        else
          existing
        end
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = backend_read(key, options)
        if value != nil
          backend_delete(key, **options)
          options[:raw] ? value.to_s : value
        end
      end

      # (see Proxy#clear)
      def clear(options = {})
        backend.clear
        self
      end

      # (see Proxy#slice)
      def slice(*keys, **options)
        hash = backend.read_multi(*keys)
        if (expires = expires_value(options, nil)) != nil
          hash.each do |key, value|
            backend_write(key, value, expires_in: expires ? expires.seconds : nil, **options)
          end
        end
        if options[:raw]
          hash.each do |key, value|
            hash[key] = value.to_s if value != nil
          end
        end
        hash
      end

      # (see Proxy#values_at)
      def values_at(*keys, **options)
        hash = slice(*keys, **options)
        keys.map { |key| hash[key] }
      end

      # (see Proxy#merge!)
      def merge!(pairs, options = {})
        if block_given?
          existing = slice(*pairs.map { |k, _| k }, **options)
          pairs = pairs.map do |key, new_value|
            if existing.key?(key)
              new_value = yield(key, existing[key], new_value)
            end

            [key, new_value]
          end
        end

        hash = Hash === pairs ? pairs : Hash[pairs.to_a]
        expires = expires_value(options)
        backend_write_multi(hash, expires_in: expires ? expires.seconds : nil, **options)
        self
      end

      private

      def expires_value(options, default = config.expires)
        super.tap { options.delete(:expires) unless options.frozen? }
      end

      delegate :decrement, :delete, :exist?, :fetch, :increment, :read, :write, :write_multi,
               to: :@backend,
               prefix: :backend
      private :backend_decrement, :backend_delete, :backend_exist?,
              :backend_fetch, :backend_increment, :backend_read,
              :backend_write, :backend_write_multi

      # @api private
      module Rails5Support
        private

        def backend_decrement(*args, **options)
          super(*args, options)
        end

        def backend_delete(*args, **options)
          super(*args, options)
        end

        def backend_exist?(*args, **options)
          super(*args, options)
        end

        def backend_fetch(*args, **options)
          super(*args, options)
        end

        def backend_increment(*args, **options)
          super(*args, options)
        end

        def backend_read(*args, **options)
          super(*args, options)
        end

        def backend_write(*args, **options)
          super(*args, options)
        end

        def backend_write_multi(*args, **options)
          super(*args, options)
        end
      end

      prepend Rails5Support if ::ActiveSupport.version < ::Gem::Version.new('6.1.0')
    end
  end
end
