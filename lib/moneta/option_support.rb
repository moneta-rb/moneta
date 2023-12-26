module Moneta
  # @api private
  module OptionSupport
    # Return Moneta store with default options or additional proxies
    #
    # For legacy reasons, it is permitted to pass a :prefix option, which
    # will behave the same as using the {#prefix} method:
    #
    # @example
    #   store.with(prefix: 'x') # equivalent to:
    #   store.prefix('x')
    #
    # @param [Hash] options Options to merge
    # @return [Moneta store]
    # @api public
    def with(options = {}, &block)
      adapter = self

      if block
        builder = Builder.new(&block)
        builder.adapter(adapter)
        adapter = builder.build.last
      end

      if prefix = options.delete(:prefix)
        adapter = adapter.prefix(prefix)
      end

      !options.empty? ? OptionMerger.new(adapter, options) : adapter
    end

    # Return Moneta store with default option raw: true
    #
    # @return [OptionMerger]
    # @api public
    def raw
      @raw ||=
        begin
          store = with(raw: true, only: [:load, :store, :create, :delete, :values_at, :slice, :fetch_values, :merge!])
          store.instance_variable_set(:@raw, store)
          store
        end
    end

    # Return Moneta store with prefixed keys.
    #
    # Prefixes add up, so:
    #
    # @example
    #   store.prefix('a:').prefix('b:') # is equivalent to:
    #   store.prefix('a:b:')
    #
    # @param [String] prefix Key prefix
    # @return [Transformer]
    # @api public
    def prefix(prefix)
      Transformer.new(self, key: :prefix, prefix: prefix)
    end

    # Return Moneta store with default expiration time
    #
    # @param [Integer] expires Default expiration time
    # @return [OptionMerger]
    # @api public
    def expires(expires)
      with(expires: expires, only: [:store, :create, :increment, :merge!])
    end
  end
end
