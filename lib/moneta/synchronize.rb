module Moneta
  # Base class for {Mutex} and {Semaphore}
  # @api private
  class SynchronizePrimitive
    # Synchronize block
    #
    # @api public
    # @yieldparam Synchronized block
    # @return [Object] result of block
    def synchronize
      enter
      yield
    ensure
      leave
    end

    # Try to enter critical section (nonblocking)
    #
    # @api public
    # @return [Boolean] true if the lock was acquired
    def try_enter
      raise 'Already locked' if @locked
      enter_primitive ? @locked = true : false
    end
    alias_method :try_lock, :try_enter

    # Enter critical section (blocking)
    #
    # @api public
    # @param [Number] timeout Maximum time to wait
    # @param [Number] wait Sleep time between tries to acquire lock
    # @return [Boolean] true if the lock was aquired
    def enter(timeout = nil, wait = 0.01)
      time_at_timeout = Time.now + timeout if timeout
      while !timeout || Time.now < time_at_timeout
        return true if try_enter
        sleep(wait)
      end
      false
    end
    alias_method :lock, :enter

    # Leave critical section
    #
    # @api public
    def leave
      raise 'Not locked' unless @locked
      leave_primitive
      @locked = false
      nil
    end
    alias_method :unlock, :leave

    # Is the lock acquired?
    #
    # @api public
    def locked?
      @locked
    end
  end

  # Distributed/shared store-wide mutex
  #
  # @example Use `Moneta::Mutex`
  #     mutex = Moneta::Mutex.new(store, 'mutex')
  #     mutex.synchronize do
  #       # Synchronized access
  #       store['counter'] += 1
  #     end
  #
  # @api public
  class Mutex < SynchronizePrimitive
    # @param [Moneta store] store The store we want to lock
    # @param [Object] lock Key of the lock entry
    def initialize(store, lock)
      raise 'Store must support feature :create' unless store.supports?(:create)
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
  #
  # @example Use `Moneta::Semaphore`
  #     semaphore = Moneta::Semaphore.new(store, 'semaphore', 2)
  #     semaphore.synchronize do
  #       # Synchronized access
  #       # ...
  #     end
  #
  # @api public
  class Semaphore < SynchronizePrimitive
    # @param [Moneta store] store The store we want to lock
    # @param [Object] counter Key of the counter entry
    # @param [Fixnum] max Maximum number of threads which are allowed to enter the critical section
    def initialize(store, counter, max = 1)
      raise 'Store must support feature :increment' unless store.supports?(:increment)
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
