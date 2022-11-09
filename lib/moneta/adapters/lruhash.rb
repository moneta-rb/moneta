module Moneta
  module Adapters
    # LRUHash backend
    #
    # Based on {https://rubygems.org/gems/lru_redux lru_redux} but measures
    # both memory usage and hash size.
    #
    # @api public
    class LRUHash < Adapter
      include IncrementSupport
      include CreateSupport

      config :max_size, default: 1024000
      config(:max_value) { |max_size:, max_value:, **| [max_value, max_size].compact.min }
      config :max_count, default: 10240

      supports :each_key

      backend { {} }

      # @param [Hash] options
      # @option options [Integer] :max_size (1024000) Maximum byte size of all values, nil disables the limit
      # @option options [Integer] :max_value (options[:max_size]) Maximum byte size of one value, nil disables the limit
      # @option options [Integer] :max_count (10240) Maximum number of values, nil disables the limit
      def initialize(options = {})
        super
        clear
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        backend.key?(key)
      end

      # (see Proxy#each_key)
      def each_key(&block)
        return enum_for(:each_key) { backend.length } unless block_given?

        # The backend needs to be duplicated because reading mutates this
        # store.
        backend.dup.each_key { |k| yield(k) }
        self
      end

      # (see Proxy#load)
      def load(key, options = {})
        if value = backend.delete(key)
          backend[key] = value
          value
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        if config.max_value && value.bytesize > config.max_value
          delete(key)
        else
          if config.max_size
            if old_value = backend.delete(key)
              @size -= old_value.bytesize
            end
            @size += value.bytesize
          end
          backend[key] = value
          drop while config.max_size && @size > config.max_size || config.max_count && backend.size > config.max_count
        end
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        if value = backend.delete(key) and config.max_size
          @size -= value.bytesize
        end
        value
      end

      # (see Proxy#clear)
      def clear(options = {})
        backend.clear
        @size = 0
        self
      end

      # Drops the least-recently-used pair, if any
      #
      # @param [Hash] options Options to merge
      # @return [(Object, String), nil] The dropped pair, if any
      def drop(options = {})
        if key = backend.keys.first
          [key, delete(key)]
        end
      end
    end
  end
end
