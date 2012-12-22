module Moneta
  class OptionMerger < Wrapper
    def initialize(adapter, optionmerger)
      super
      @optionmerger = optionmerger
    end

    def wrap(method, *args)
      options = args.last
      options.merge!(@optionmerger[method]) if Hash === options && @optionmerger.include?(method)
      yield
    end
  end
end

