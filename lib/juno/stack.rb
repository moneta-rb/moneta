module Juno
  # Combines multiple stores. Reads return the result from the first store,
  # writes go to all stores.
  #
  # Example:
  #
  #   Juno.build do
  #     use(:Stack) do
  #       add { adapter :Redis }
  #       add { adapter :File, :dir => 'data' }
  #       add { adapter :File, :dir => 'replicate' }
  #     end
  #   end
  class Stack < Base
    class DSL
      attr_reader :stack

      def initialize(options, &block)
        @stack = options[:stack].to_a
        instance_eval(&block)
      end

      def add(options = {}, &block)
        @stack << (Hash === options ? Juno.build(options, &block) : options)
        nil
      end
    end

    attr_reader :stack

    def initialize(options = {}, &block)
      @stack = DSL.new(options, &block).stack
    end

    def key?(key, options = {})
      @stack.any? {|s| s.key?(key) }
    end

    def load(key, options = {})
      @stack.each do |s|
        value = s.load(key, options)
        return value if value
      end
      nil
    end

    def store(key, value, options = {})
      @stack.each {|s| s.store(key, value, options) }
      value
    end

    def delete(key, options = {})
      @stack.inject(nil) do |value, s|
        v = s.delete(key, options)
        value || v
      end
    end

    def clear(options = {})
      @stack.each {|s| s.clear }
      self
    end

    def close
      @stack.each {|s| s.close }
      nil
    end
  end
end
