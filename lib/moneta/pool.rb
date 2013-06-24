require 'thread'

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
    # @option options [String] :mutex (::Mutex.new) Mutex object
    def initialize(options = {}, &block)
      super(nil)
      @mutex = options[:mutex] || ::Mutex.new
      @builder = Builder.new(&block)
      @pool, @all = [], []
    end

    def close
      @mutex.synchronize do
        raise '#close can only when no thread is using the pool' if @all.size != @pool.size
        @all.each(&:close)
        @all = @pool = nil
      end
    end

    protected

    def adapter
      Thread.current[thread_id]
    end

    def thread_id
      "Moneta::Pool(#{object_id})"
    end

    def wrap(*args)
      store = Thread.current[thread_id] = pop
      yield
    ensure
      Thread.current[thread_id] = nil
      @mutex.synchronize { @pool << store }
    end

    def pop
      if @mutex.synchronize { @pool.empty? }
        store = @builder.build.last
        @mutex.synchronize { @all << store }
        store
      else
        @mutex.synchronize { @pool.pop }
      end
    end
  end
end
