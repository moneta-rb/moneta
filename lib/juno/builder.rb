module Juno
  # Builder implements the DSL to build a chain of store proxies
  # @api private
  class Builder
    # @api private
    def build
      klass, options, block = @proxies.first
      store = klass.new(options, &block)
      @proxies[1..-1].each do |proxy|
        klass, options, block = proxy
        store = klass.new(store, options, &block)
      end
      store
    end

    def initialize(&block)
      raise 'No block given' unless block_given?
      @proxies = []
      instance_eval(&block)
    end

    # Add proxy to chain
    #
    # @param [Symbol or Class] proxy Name of proxy class or proxy class
    # @param [Hash] options Options hash
    def use(proxy, options = {}, &block)
      proxy = Juno.const_get(proxy) if Symbol === proxy
      raise 'You must give a Class or a Symbol' unless Class === proxy
      @proxies.unshift [proxy, options, block]
      nil
    end

    # Add adapter to chain
    #
    # @param [Symbol] name Name of adapter class
    # @param [Hash] options Options hash
    def adapter(name, options = {}, &block)
      use(Adapters.const_get(name), options, &block)
    end
  end
end
