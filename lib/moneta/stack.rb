module Moneta
  # Combines multiple stores. Reads return the result from the first store,
  # writes go to all stores.
  #
  # @example Add `Moneta::Stack` to proxy stack
  #   Moneta.build do
  #     use(:Stack) do
  #       add { adapter :Redis }
  #       add { adapter :File, :dir => 'data' }
  #       add { adapter :File, :dir => 'replicate' }
  #     end
  #   end
  #
  # @api public
  class Stack
    include Defaults

    # @api private
    class DSL
      attr_reader :stack

      def initialize(options, &block)
        @stack = options[:stack].to_a
        instance_eval(&block)
      end

      def add(store = nil, &block)
        raise ArgumentError, 'Only argument or block allowed' if store && block
        @stack << (store || Moneta.build(&block))
        nil
      end
    end

    attr_reader :stack

    def initialize(options = {}, &block)
      @stack = DSL.new(options, &block).stack
    end

    def key?(key, options = {})
      @stack.any? {|s| s.key?(key, options) }
    end

    def load(key, options = {})
      @stack.each do |s|
        value = s.load(key, options)
        return value if value != nil
      end
      nil
    end

    def store(key, value, options = {})
      @stack.each {|s| s.store(key, value, options) }
      value
    end

    def increment(key, amount = 1, options = {})
      last = nil
      @stack.each {|s| last = s.increment(key, amount, options) }
      last
    end

    def delete(key, options = {})
      @stack.inject(nil) do |value, s|
        v = s.delete(key, options)
        value || v
      end
    end

    def clear(options = {})
      @stack.each {|s| s.clear(options) }
      self
    end

    def close
      @stack.each {|s| s.close }
      nil
    end
  end
end
