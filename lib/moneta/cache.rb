module Moneta
  # Combines two stores. One is used as cache, the other as backend adapter.
  #
  # @example Add `Moneta::Cache` to proxy stack
  #   Moneta.build do
  #     use(:Cache) do
  #      adapter { adapter :File, :dir => 'data' }
  #      cache { adapter :Memory }
  #     end
  #   end
  #
  # @api public
  class Cache
    include Defaults

    # @api private
    class DSL
      def initialize(store, &block)
        @store = store
        instance_eval(&block)
      end

      # @api public
      def adapter(store = nil, &block)
        raise 'Adapter already set' if @store.adapter
        raise ArgumentError, 'Only argument or block allowed' if store && block
        @store.adapter = store || Moneta.build(&block)
      end

      # @api public
      def cache(store = nil, &block)
        raise 'Cache already set' if @store.cache
        raise ArgumentError, 'Only argument or block allowed' if store && block
        @store.cache = store || Moneta.build(&block)
      end
    end

    attr_accessor :cache, :adapter

    # @param [Hash] options Options hash
    # @option options [Moneta store] :cache Moneta store used as cache
    # @option options [Moneta store] :adapter Moneta store used as adapter
    # @yieldparam Builder block
    def initialize(options = {}, &block)
      @cache, @adapter = options[:cache], options[:adapter]
      DSL.new(self, &block) if block_given?
    end

    # (see Proxy#key?)
    def key?(key, options = {})
      @cache.key?(key, options) || @adapter.key?(key, options)
    end

    # (see Proxy#load)
    def load(key, options = {})
      if options[:sync] || (value = @cache.load(key, options)) == nil
        value = @adapter.load(key, options)
        @cache.store(key, value, options) if value != nil
      end
      value
    end

    # (see Proxy#store)
    def store(key, value, options = {})
      @cache.store(key, value, options)
      @adapter.store(key, value, options)
    end

    # (see Proxy#increment)
    def increment(key, amount = 1, options = {})
      @cache.delete(key, options)
      @adapter.increment(key, amount, options)
    end

    # (see Proxy#create)
    def create(key, value, options = {})
      if @adapter.create(key, value, options)
        @cache.store(key, value, options)
        true
      else
        false
      end
    end

    # (see Proxy#delete)
    def delete(key, options = {})
      @cache.delete(key, options)
      @adapter.delete(key, options)
    end

    # (see Proxy#clear)
    def clear(options = {})
      @cache.clear(options)
      @adapter.clear(options)
      self
    end

    # (see Proxy#close)
    def close
      @cache.close
      @adapter.close
    end

    # (see Proxy#features)
    def features
      @features ||= ((@cache.features + [:create, :increment]) & @adapter.features).freeze
    end
  end
end
