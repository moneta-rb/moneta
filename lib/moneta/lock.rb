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
      if locked?
        yield
      else
        lock!(&block)
      end
    end

    def locks
      Thread.current['Moneta::Lock'] ||= Set.new
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
