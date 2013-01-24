require 'dalli'

module Moneta
  module Adapters
    # Memcached backend (using gem dalli)
    # @api public
    class MemcachedDalli
      include Defaults
      include ExpiresSupport

      supports :create, :increment

      # @param [Hash] options
      # @option options [String] :server ('127.0.0.1:11211') Memcached server
      # @option options [Integer] :expires Default expiration time
      # @option options Other options passed to `Dalli::Client#new`
      def initialize(options = {})
        self.default_expires = options.delete(:expires)
        server = options.delete(:server) || '127.0.0.1:11211'
        @cache = ::Dalli::Client.new(server, options)
      end

      # (see Proxy#load)
      def load(key, options = {})
        value = @cache.get(key)
        if value
          expires = expires_value(options, nil)
          @cache.set(key, value, expires || nil, :raw => true) if expires != nil
          value
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @cache.set(key, value, expires_value(options) || nil, :raw => true)
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = @cache.get(key)
        @cache.delete(key)
        value
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        # FIXME: There is a Dalli bug, load(key) returns a wrong value after increment
        # therefore we set default = nil and create the counter manually
	# See https://github.com/mperham/dalli/issues/309
        result = amount >= 0 ? @cache.incr(key, amount, nil, nil) : @cache.decr(key, -amount, nil, nil)
        if result
          result
        elsif create(key, amount.to_s, options)
          amount
        else
          increment(key, amount, options)
        end
      end

      # (see Proxy#clear)
      def clear(options = {})
        @cache.flush_all
        self
      end

      # (see Defaults#create)
      def create(key, value, options = {})
        @cache.add(key, value, expires_value(options) || nil, :raw => true)
      end

      # (see Proxy#close)
      def close
        @cache.close
        nil
      end
    end
  end
end
