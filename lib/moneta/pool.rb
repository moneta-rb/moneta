module Moneta
  # Creates a pool of stores.
  # Each thread gets its own store.
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
