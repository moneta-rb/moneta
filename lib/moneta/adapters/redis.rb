require 'redis'

module Moneta
  module Adapters
    # Redis backend
    # @api public
    class Redis < Adapter
      include ExpiresSupport

      supports :create, :increment, :each_key

      # @!method initialize(options = {})
      #   @param [Hash] options
      #   @option options [Integer] :expires Default expiration time
      #   @option options [::Redis] :backend Use existing backend instance
      #   @option options Other options passed to `Redis#new`
      backend { |**options| ::Redis.new(options) }

      # (see Proxy#key?)
      #
      # This method considers false and 0 as "no-expire" and every positive
      # number as a time to live in seconds.
      def key?(key, options = {})
        with_expiry_update(key, default: nil, **options) do |pipeline_handle|
          if pipeline_handle.respond_to?(:exists?)
            pipeline_handle.exists?(key)
          else
            pipeline_handle.exists(key)
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
        with_expiry_update(key, default: nil, **options) do |pipeline_handle|
          pipeline_handle.get(key)
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
        @backend.pipelined do |pipeline|
          future = pipeline.get(key)
          pipeline.del(key)
        end
        future.value
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        with_expiry_update(key, **options) do |pipeline_handle|
          pipeline_handle.incrby(key, amount)
        end
      end

      # (see Proxy#clear)
      def clear(options = {})
        @backend.flushdb
        self
      end

      # (see Defaults#create)
      def create(key, value, options = {})
        expires = expires_value(options, config.expires)

        if @backend.setnx(key, value)
          update_expires(@backend, key, expires)
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
        with_expiry_update(*keys, default: nil, **options) do |pipeline_handle|
          pipeline_handle.mget(*keys)
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

        with_expiry_update(*keys, **options) do |pipeline_handle|
          pipeline_handle.mset(*pairs.to_a.flatten(1))
        end

        self
      end

      protected

      def update_expires(pipeline_handle, key, expires)
        case expires
        when false
          pipeline_handle.persist(key)
        when Numeric
          pipeline_handle.pexpire(key, (expires * 1000).to_i)
        end
      end

      def with_expiry_update(*keys, default: config.expires, **options)
        expires = expires_value(options, default)
        if expires == nil
          yield(@backend)
        else
          future = nil
          @backend.multi do |pipeline|
            # as of redis 4.6 calling redis methods on the redis client itself
            # is deprecated in favor of a pipeline handle provided by the
            # +multi+ call. This will cause in error in redis >= 5.0.
            #
            # In order to continue supporting redis versions < 4.6, the following
            # fallback has been introduced and can be removed once moneta
            # no longer supports redis < 4.6.

            pipeline_handle = pipeline || @backend
            future = yield(pipeline_handle)
            keys.each { |key| update_expires(pipeline_handle, key, expires) }
          end
          future.value
        end
      end
    end
  end
end
