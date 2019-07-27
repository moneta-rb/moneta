require 'memcached'

module Moneta
  module Adapters
    # Memcached backend (using gem memcached)
    # @api public
    class MemcachedNative
      include Defaults
      include ExpiresSupport

      supports :create, :increment
      attr_reader :backend

      # @param [Hash] options
      # @option options [String] :server ('127.0.0.1:11211') Memcached server
      # @option options [String] :namespace Key namespace
      # @option options [Integer] :expires (604800) Default expiration time
      # @option options [::Memcached] :backend Use existing backend instance
      # @option options Other options passed to `Memcached#new`
      def initialize(options = {})
        server = options.delete(:server) || '127.0.0.1:11211'
        self.default_expires = options.delete(:expires)
        @backend = options[:backend] ||
          begin
            options[:prefix_key] = options.delete(:namespace) if options[:namespace]
            # We don't want a limitation on the key charset. Therefore we use the binary protocol.
            # It is also faster.
            options[:binary_protocol] = true unless options.include?(:binary_protocol)
            ::Memcached.new(server, options)
          end
      end

      # (see Proxy#load)
      def load(key, options = {})
        value = @backend.get(key, false)
        if value
          expires = expires_value(options, nil)
          unless expires == nil
            Numeric === expires and expires = expires.to_i
            @backend.set(key, value, expires || 0, false)
          end
          value
        end
      rescue ::Memcached::NotFound
        nil
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        # TTL must be Integer
        expires = expires_value(options)
        Numeric === expires and expires = expires.to_i
        @backend.set(key, value, expires || 0, false)
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = @backend.get(key, false)
        @backend.delete(key)
        value
      rescue ::Memcached::NotFound
        nil
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        result = if amount >= 0
                   @backend.increment(key, amount)
                 else
                   @backend.decrement(key, -amount)
                 end
        # HACK: Throw error if applied to invalid value
        # see https://github.com/evan/memcached/issues/110
        Integer((@backend.get(key, false) rescue 0)) if result == 0
        result
      rescue ::Memcached::NotFound
        retry unless create(key, amount.to_s, options)
        amount
      end

      # (see Defaults#create)
      def create(key, value, options = {})
        expires = expires_value(options)
        Numeric === expires and expires = expires.to_i
        @backend.add(key, value, expires || 0, false)
        true
      rescue ::Memcached::ConnectionDataExists
        false
      end

      # (see Proxy#clear)
      def clear(options = {})
        @backend.flush
        self
      end

      # (see Proxy#close)
      def close
        @backend.reset
        nil
      end
    end
  end
end
