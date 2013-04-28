module Moneta
  # Builder implements the DSL to build a stack of Moneta store proxies
  # @api private
  class Builder
    # @yieldparam Builder dsl code block
    def initialize(&block)
      raise ArgumentError, 'No block given' unless block_given?
      @adapter = nil
      @proxies = []
      instance_eval(&block)
    end

    # Build proxy stack
    #
    # @return [Object] Generated Moneta proxy stack
    # @api public
    def build
      adapter = @adapter
      if Array === adapter
        klass, options, block = adapter
        adapter = klass.new(options, &block)
      end
      @proxies.inject([adapter]) do |stores, proxy|
        klass, options, block = proxy
        stores << klass.new(stores.last, options, &block)
      end
    end

    # Add proxy to stack
    #
    # @param [Symbol/Class] proxy Name of proxy class or proxy class
    # @param [Hash] options Options hash
    # @api public
    def use(proxy, options = {}, &block)
      raise 'Cannot add another proxy because the adapter is already specified.' if @adapter
      proxy = Moneta.const_get(proxy) if Symbol === proxy
      raise ArgumentError, 'You must give a Class or a Symbol' unless Class === proxy
      @proxies.unshift [proxy, options, block]
      nil
    end

    # Add adapter to stack
    #
    # @param [Symbol/Class/Moneta store] adapter Name of adapter class, adapter class or Moneta store
    # @param [Hash] options Options hash
    # @api public
    def adapter(adapter, options = {}, &block)
      raise 'Cannot set the adapter because the adapter is already specified.' if @adapter
      @adapter =
        case adapter
        when Symbol
          [Adapters.const_get(adapter), options, block]
        when Class
          [adapter, options, block]
        else
          raise ArgumentError, 'Adapter must be a Moneta store' unless adapter.respond_to?(:load) && adapter.respond_to?(:store)
          raise ArgumentError, 'No options allowed' unless options.empty?
          adapter
        end
    end
  end
end
