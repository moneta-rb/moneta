module Moneta
  # Builder implements the DSL to build a stack of Moneta store proxies
  # @api private
  class Builder
    # @yieldparam Builder dsl code block
    def initialize(&block)
      raise ArgumentError, 'No block given' unless block_given?
      @proxies = []
      instance_eval(&block)
    end

    # Build proxy stack
    #
    # @return [Object] Generated Moneta proxy stack
    # @api public
    def build
      adapter = @proxies.first
      if Array === adapter
        klass, options, block = adapter
        adapter = new_proxy(klass, options, &block)
        check_arity(klass, adapter, 1)
      end
      @proxies[1..-1].inject([adapter]) do |result, proxy|
        klass, options, block = proxy
        proxy = new_proxy(klass, result.last, options, &block)
        check_arity(klass, proxy, 2)
        result << proxy
      end
    end

    # Add proxy to stack
    #
    # @param [Symbol/Class] proxy Name of proxy class or proxy class
    # @param [Hash] options Options hash
    # @api public
    def use(proxy, options = {}, &block)
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
      case adapter
      when Symbol
        use(Adapters.const_get(adapter), options, &block)
      when Class
        use(adapter, options, &block)
      else
        raise ArgumentError, 'Adapter must be a Moneta store' unless adapter.respond_to?(:load) && adapter.respond_to?(:store)
        raise ArgumentError, 'No options allowed' unless options.empty?
        @proxies.unshift adapter
        nil
      end
    end

    protected

    def new_proxy(klass, *args, &block)
      klass.new(*args, &block)
    rescue ArgumentError => ex
      check_arity(klass, klass.allocate, args.size)
      raise
    end

    def check_arity(klass, proxy, expected)
      args = proxy.method(:initialize).arity.abs
      raise(ArgumentError, %{#{klass.name}#new accepts wrong number of arguments (#{args} accepted, #{expected} expected)

Please check your Moneta builder block:
  * Proxies must be used before the adapter
  * Only one adapter is allowed
  * The adapter must be used last
}) if args != expected
    end
  end

end
