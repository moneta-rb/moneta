require 'dalli'

module Moneta
  module Adapters
    # Memcached backend (using gem dalli)
    # @api public
    class MemcachedDalli
      include Defaults
      include ExpiresSupport

      supports :create, :increment
      attr_reader :backend

      # @param [Hash] options
      # @option options [String] :server ('127.0.0.1:11211') Memcached server
      # @option options [Integer] :expires Default expiration time
      # @option options [::Dalli::Client] :backend Use existing backend instance
      # @option options Other options passed to `Dalli::Client#new`
      def initialize(options = {})
        self.default_expires = options.delete(:expires)
        @backend = options[:backend] ||
          begin
            server = options.delete(:server) || '127.0.0.1:11211'
            ::Dalli::Client.new(server, options)
          end
      end

      # (see Proxy#load)
      def load(key, options = {})
        value = @backend.get(key)
        if value
          expires = expires_value(options, nil)
          @backend.set(key, value, expires || nil, raw: true) if expires != nil
          value
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @backend.set(key, value, expires_value(options) || nil, raw: true)
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = @backend.get(key)
        @backend.delete(key)
        value
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        result =
          if amount >= 0
            @backend.incr(key, amount, expires_value(options) || nil)
          else
            @backend.decr(key, -amount, expires_value(options) || nil)
          end
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
        @backend.flush_all
        self
      end

      # (see Defaults#create)
      def create(key, value, options = {})
        !!@backend.add(key, value, expires_value(options) || nil, raw: true)
      end

      # (see Proxy#close)
      def close
        @backend.close
        nil
      end

      # (see Defaults#slice)
      def slice(*keys, **options)
        @backend.get_multi(keys).tap do |pairs|
          next if pairs.empty?
          expires = expires_value(options, nil)
          next if expires == nil
          expires = expires.to_i if Numeric === expires
          expires ||= 0
          @backend.multi do
            pairs.each do |key, value|
              @backend.set(key, value, expires, false)
            end
          end
        end
      end

      # (see Defaults#values_at)
      def values_at(*keys, **options)
        pairs = slice(*keys, **options)
        keys.map { |key| pairs.delete(key) }
      end

      # (see Defaults#merge!)
      def merge!(pairs, options = {})
        expires = expires_value(options)
        expires = expires.to_i if Numeric === expires
        expires ||= nil

        if block_given?
          keys = pairs.map { |key, _| key }.to_a
          old_pairs = @backend.get_multi(keys)
          pairs = pairs.map do |key, new_value|
            if old_pairs.key? key
              new_value = yield(key, old_pairs[key], new_value)
            end
            [key, new_value]
          end
        end

        @backend.multi do
          pairs.each do |key, value|
            @backend.set(key, value, expires, raw: true)
          end
        end

        self
      end
    end
  end
end
