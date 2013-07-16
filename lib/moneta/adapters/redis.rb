require 'redis'

module Moneta
  module Adapters
    # Redis backend
    # @api public
    class Redis
      include Defaults
      include ExpiresSupport

      supports :create, :increment
      attr_reader :backend

      # @param [Hash] options
      # @option options [Integer] :expires Default expiration time
      # @option options [::Redis] :backend Use existing backend instance
      # @option options Other options passed to `Redis#new`
      def initialize(options = {})
        self.default_expires = options.delete(:expires)
        @backend = options[:backend] || ::Redis.new(options)
      end

      # (see Proxy#key?)
      #
      # This method considers false and 0 as "no-expire" and every positive
      # number as a time to live in seconds.
      def key?(key, options = {})
        if @backend.exists(key)
          update_expires(key, options, nil)
          true
        else
          false
        end
      end

      # (see Proxy#load)
      def load(key, options = {})
        value = @backend.get(key)
        update_expires(key, options, nil)
        value
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        if expires = expires_value(options)
          @backend.setex(key, expires, value)
        else
          @backend.set(key, value)
        end
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        if value = load(key, options)
          @backend.del(key)
          value
        end
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        value = @backend.incrby(key, amount)
        update_expires(key, options)
        value
      end

      # (see Proxy#clear)
      def clear(options = {})
        @backend.flushdb
        self
      end

      # (see Defaults#create)
      def create(key, value, options = {})
        if @backend.setnx(key, value)
          update_expires(key, options)
          true
        else
          false
        end
      end

      # (see Proxy#close)
      def close
        @backend.quit
        nil
      end

      protected

      def update_expires(key, options, default = @default_expires)
        case expires = expires_value(options, default)
        when false
          @backend.persist(key)
        when Numeric
          @backend.expire(key, expires)
        end
      end
    end
  end
end
