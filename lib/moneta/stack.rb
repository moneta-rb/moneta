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
      def initialize(stack, &block)
        @stack = stack
        instance_eval(&block)
      end

      # @api public
      def add(store = nil, &block)
        raise ArgumentError, 'Only argument or block allowed' if store && block
        @stack << (store || Moneta.build(&block))
        nil
      end
    end

    attr_reader :stack

    # @param [Hash] options Options hash
    # @option options [Array] :stack Array of Moneta stores
    # @yieldparam Builder block
    def initialize(options = {}, &block)
      @stack = options[:stack].to_a
      DSL.new(@stack, &block) if block_given?
    end

    # (see Proxy#key?)
    def key?(key, options = {})
      @stack.any? {|s| s.key?(key, options) }
    end

    # (see Proxy#load)
    def load(key, options = {})
      @stack.each do |s|
        value = s.load(key, options)
        return value if value != nil
      end
      nil
    end

    # (see Proxy#store)
    def store(key, value, options = {})
      @stack.each {|s| s.store(key, value, options) }
      value
    end

    # (see Proxy#increment)
    def increment(key, amount = 1, options = {})
      last = nil
      @stack.each {|s| last = s.increment(key, amount, options) }
      last
    end

    # (see Proxy#create)
    def create(key, value, options = {})
      last = false
      @stack.each {|s| last = s.create(key, value, options) }
      last
    end

    # (see Proxy#delete)
    def delete(key, options = {})
      @stack.inject(nil) do |value, s|
        v = s.delete(key, options)
        value || v
      end
    end

    # (see Proxy#clear)
    def clear(options = {})
      @stack.each {|s| s.clear(options) }
      self
    end

    # (see Proxy#close)
    def close
      @stack.each {|s| s.close }
      nil
    end

    # (see Proxy#features)
    def features
      @features ||=
        begin
          features = @stack.map(&:features)
          features.inject(features.first, &:&).freeze
        end
    end
  end
end
