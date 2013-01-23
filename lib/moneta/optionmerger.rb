module Moneta
  # @api private
  class OptionMerger < Wrapper
    METHODS = [:key?, :load, :store, :create, :delete, :increment, :clear].freeze

    attr_reader :default_options

    # @param [Moneta store] adapter underlying adapter
    # @param [Hash] options
    def initialize(adapter, options = {})
      super(adapter, options)

      @default_options = adapter.respond_to?(:default_options) ? adapter.default_options.dup : {}

      if options.include?(:only)
        raise ArgumentError, 'Either :only or :except is allowed' if options.include?(:except)
        methods = [options.delete(:only)].compact.flatten
      elsif options.include?(:except)
        methods = METHODS - [options.delete(:except)].compact.flatten
      else
        methods = METHODS
      end

      methods.each do |method|
        if oldopts = @default_options[method]
          newopts = (@default_options[method] = oldopts.merge(options))
          newopts[:prefix] = "#{oldopts[:prefix]}#{options[:prefix]}" if oldopts[:prefix] || options[:prefix]
        else
          @default_options[method] = options
        end
      end
    end

    protected

    def wrap(method, *args)
      options = args.last
      options.merge!(@default_options[method]) if Hash === options && @default_options.include?(method)
      yield
    end
  end
end

