module Moneta
  module Adapters
    # ActiveSupport::Cache::Store adapter
    # @api public
    class ActiveSupportCache
      include Defaults
      include ExpiresSupport

      supports :increment

      # @param [Hash] options
      # @option options [Numeric] :expires default expiration in seconds
      def initialize(options = {})
        self.default_expires = options.delete(:expires)
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
        @backend.exist?(key).tap do |exists|
          if exists && (expires = expires_value(options, nil)) != nil
            value = @backend.read(key, options)
            @backend.write(key, value, options.merge(expires_in: expires ? expires.seconds : nil))
          end
        end
      end

      # (see Proxy#load)
      def load(key, options = {})
        expires = expires_value(options, nil)
        value = @backend.read(key, options)
        if value and expires != nil
          @backend.write(key, value, options.merge(expires_in: expires ? expires.seconds : nil))
        end
        value
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        expires = expires_value(options)
        @backend.write(key, value, options.merge(expires_in: expires ? expires.seconds : nil))
        value
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        expires = expires_value(options)
        options.delete(:raw)
        existing = Integer(@backend.fetch(key, options.merge(raw: true)) { 0 })
        if amount > 0
          @backend.increment(key, amount, options.merge(expires_in: expires ? expires.seconds : nil))
        elsif amount < 0
          @backend.decrement(key, -amount, options.merge(expires_in: expires ? expires.seconds : nil))
        else
          existing
        end
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = @backend.read(key, options)
        if value != nil
          @backend.delete(key, options)
          options[:raw] ? value.to_s : value
        end
      end

      # (see Proxy#clear)
      def clear(options = {})
        @backend.clear
        self
      end

      # (see Proxy#slice)
      def slice(*keys, **options)
        hash = @backend.read_multi(*keys)
        if (expires = expires_value(options, nil)) != nil
          hash.each do |key, value|
            @backend.write(key, value, options.merge(expires_in: expires ? expires.seconds : nil))
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
        @backend.write_multi(hash, options.merge(expires_in: expires ? expires.seconds : nil))
        self
      end

      private

      def expires_value(options, default = @default_expires)
        super.tap { options.delete(:expires) unless options.frozen? }
      end
    end
  end
end
