module Moneta
  class OptionMerger < Wrapper
    def initialize(adapter, options)
      super
      @options = options
    end

    def wrap(method, *args)
      options = args.last
      options.merge!(@options[method]) if Hash === options && @options.include?(method)
      yield
    end
  end
end

