module Moneta
  # Creates a pool of stores.
  # Each thread gets its own store.
  #
  # @example Add `Moneta::Pool` to proxy stack
  #   Moneta.build do
  #     use(:Pool) do
  #       # Every thread gets its own instance
  #       adapter :MemcachedNative
  #     end
  #   end
  #
  # @api public
  class Pool < Wrapper
    # @param [Moneta store] adapter The underlying store
    # @param [Hash] options
    def initialize(options = {}, &block)
      super(nil)
      @builder = Builder.new(&block)
      @pool, @active = [], {}
    end

    protected

    def adapter
      @active[Thread.current]
    end

    def wrap(*args)
      @pool << @builder.build.last if @pool.empty?
      @active[Thread.current] = @pool.pop
      yield
    ensure
      @pool << @active.delete(Thread.current)
    end
  end
end
