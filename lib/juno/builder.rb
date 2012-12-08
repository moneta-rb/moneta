module Juno
  # Builder implements the DSL to build a chain of store proxies
  # @api private
  class Builder
    def build
      klass, options, block = @proxies.first
      store = klass.new(@options.merge(options), &block)
      @proxies[1..-1].each do |proxy|
        klass, options, block = proxy
        store = klass.new(store, @options.merge(options), &block)
      end
      store
    end

    def initialize(options = {}, &block)
      raise 'No block given' unless block_given?
      raise 'Options must be Hash' unless Hash === options
      @options = options
      @proxies = []
      instance_eval(&block)
    end

    def use(proxy, options = {}, &block)
      proxy = Juno.const_get(proxy) if Symbol === proxy
      raise 'You must give a Class or a Symbol' unless Class === proxy
      @proxies.unshift [proxy, options, block]
    end

    def adapter(name, options = {}, &block)
      use(Adapters.const_get(name), options, &block)
    end
  end
end
