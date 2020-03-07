require 'set'

module Moneta
  # Locks the underlying stores with a Mutex
  # @api public
  class Lock < Wrapper
    # @param [Moneta store] adapter The underlying store
    # @param [Hash] options
    # @option options [String] :mutex (::Mutex.new) Mutex object
    def initialize(adapter, options = {})
      super
      @lock = options[:mutex] || ::Mutex.new
    end

    protected

    def wrap(name, *args, &block)
      self.locks ||= Set.new
      if locked?
        yield
      else
        lock!(&block)
      end
    end

    def locks=(locks)
      Thread.current.thread_variable_set('Moneta::Lock', locks)
    end

    def locks
      Thread.current.thread_variable_get('Moneta::Lock')
    end

    def lock!(&block)
      locks << @lock
      @lock.synchronize(&block)
    ensure
      locks.delete @lock
    end

    def locked?
      locks.include? @lock
    end
  end
end
