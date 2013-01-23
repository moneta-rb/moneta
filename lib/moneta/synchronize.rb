module Moneta
  # @api private
  class SynchronizePrimitive
    def synchronize
      enter
      yield
    ensure
      leave
    end

    def try_enter
      raise 'Already locked' if @locked
      enter_primitive ? @locked = true : false
    end
    alias_method :try_lock, :try_enter

    def enter(timeout = nil, wait = 0.01)
      total = 0
      while !timeout || total < timeout
        return true if try_enter
        sleep(wait)
        total += wait
      end
      false
    end
    alias_method :lock, :enter

    def leave
      raise 'Not locked' unless @locked
      leave_primitive
      @locked = false
      nil
    end
    alias_method :unlock, :leave

    def locked?
      @locked
    end
  end

  # Distributed/shared store-wide mutex
  # @api public
  class Mutex < SynchronizePrimitive
    def initialize(store, lock)
      @store, @lock = store, lock
    end

    protected

    def enter_primitive
      @store.create(@lock, '', :expires => false)
    end

    def leave_primitive
      @store.delete(@lock)
    end
  end

  # Distributed/shared store-wide semaphore
  # @api public
  class Semaphore < SynchronizePrimitive
    def initialize(store, counter, max = 1)
      @store, @counter, @max = store, counter, max
      @store.increment(@counter, 0, :expires => false) # Ensure that counter exists
    end

    protected

    def enter_primitive
      if @store.increment(@counter, 1) <= @max
        true
      else
        @store.decrement(@counter)
        false
      end
    end

    def leave_primitive
      @store.decrement(@counter)
    end
  end
end
