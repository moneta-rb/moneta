require 'redis'

module Moneta
  module Adapters
    # Redis backend
    # @api public
    class Redis
      include Defaults
      include ExpiresSupport

      supports :create, :increment, :each_key
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
        with_expiry_update(key, default: nil, **options) do
          if @backend.respond_to?(:exists?)
            @backend.exists?(key)
          else
            @backend.exists(key)
          end
        end
      end

      # (see Proxy#each_key)
      def each_key(&block)
        return enum_for(:each_key) unless block_given?

        @backend.scan_each { |k| yield(k) }
        self
      end

      # (see Proxy#load)
      def load(key, options = {})
        with_expiry_update(key, default: nil, **options) do
          @backend.get(key)
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        if expires = expires_value(options)
          Numeric === expires and expires = (expires * 1000).to_i
          @backend.psetex(key, expires, value)
        else
          @backend.set(key, value)
        end
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        future = nil
        @backend.pipelined do
          future = @backend.get(key)
          @backend.del(key)
        end
        future.value
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        with_expiry_update(key, **options) do
          @backend.incrby(key, amount)
        end
      end

      # (see Proxy#clear)
      def clear(options = {})
        @backend.flushdb
        self
      end

      # (see Defaults#create)
      def create(key, value, options = {})
        expires = expires_value(options, @default_expires)

        if @backend.setnx(key, value)
          update_expires(key, expires)
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

      # (see Defaults#values_at)
      def values_at(*keys, **options)
        with_expiry_update(*keys, default: nil, **options) do
          @backend.mget(*keys)
        end
      end

      # (see Defaults#merge!)
      def merge!(pairs, options = {})
        keys = pairs.map { |key, _| key }

        if block_given?
          old_values = @backend.mget(*keys)
          updates = pairs.each_with_index.with_object({}) do |(pair, i), updates|
            old_value = old_values[i]
            if old_value != nil
              key, new_value = pair
              updates[key] = yield(key, old_value, new_value)
            end
          end
          unless updates.empty?
            pairs = if pairs.respond_to?(:merge)
                      pairs.merge(updates)
                    else
                      Hash[pairs.to_a].merge!(updates)
                    end
          end
        end

        with_expiry_update(*keys, **options) do
          @backend.mset(*pairs.to_a.flatten(1))
        end

        self
      end

      protected

      def update_expires(key, expires)
        case expires
        when false
          @backend.persist(key)
        when Numeric
          @backend.pexpire(key, (expires * 1000).to_i)
        end
      end

      def with_expiry_update(*keys, default: @default_expires, **options)
        expires = expires_value(options, default)
        if expires == nil
          yield
        else
          future = nil
          @backend.multi do
            future = yield
            keys.each { |key| update_expires(key, expires) }
          end
          future.value
        end
      end
    end
  end
end
