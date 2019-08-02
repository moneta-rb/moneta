require 'set'

module Moneta
  # Creates a thread-safe pool.  Stores are in the pool are transparently
  # checked in and out in order to perform operations.
  #
  # A `max` setting can be specified in order to limit the pool size.  If `max`
  # stores are all checked out at once, the next check-out will block until one
  # of the other stores are checked in.
  #
  # A `ttl` setting can be specified, giving the number of seconds to
  # wait without any activity before shrinking the pool size back down to the
  # min size.
  #
  # A `timeout` setting can be specified, giving the number of seconds to wait
  # when checking out a store, before an error is raised.  When the pool has a
  # `:max` size, a timeout is highly advisable.
  #
  # @example Add `Moneta::Pool` to proxy stack
  #   Moneta.build do
  #     use(:Pool) do
  #       adapter :MemcachedNative
  #     end
  #   end
  #
  # @example Add `Moneta::Pool` that contains at least 2 stores, and closes any extras after 60 seconds of inactivity
  #   Moneta.build do
  #     use(:Pool, min: 2, ttl: 60) do
  #       adapter :Sqlite, file: 'test.db'
  #     end
  #   end
  #
  # @example Add `Moneta::Pool` with a max of 10 stores, and a timeout of 5 seconds for checkout
  #   Moneta.build do
  #     use(:Pool, max: 10, timeout: 5) do
  #       adapter :Sqlite, file: 'test.db'
  #     end
  #   end
  #
  # @api public
  class Pool < Wrapper
    # @api private
    class ShutdownError < ::RuntimeError; end
    class TimeoutError < ::RuntimeError; end

    # @api private
    class PoolManager
      def initialize(builder, min: 0, max: nil, ttl: nil, timeout: nil)
        @builder = builder
        @min = min
        @max = max
        @ttl = ttl
        @timeout = timeout

        @inbox = []
        @mutex = ::Mutex.new
        @resource = ::ConditionVariable.new

        @stores = Set.new
        @available = []
        @waiting = []
        @waiting_since = [] if @timeout
        @last_checkout = nil
        @stopping = false

        # Launch the manager thread
        run
      end

      def stats
        push(:stats, reply: true)
      end

      def stop
        push(:stop)
        sleep 0.1 while @thread.alive?
        nil
      end

      def kill!
        @thread.kill
        nil
      end

      def check_out
        store = push(:check_out, reply: true)
        raise store if store.is_a? ::Exception
        store
      end

      def check_in(store)
        push(:check_in, store)
      end

      private

      def run
        @thread = Thread.new do
          # Initialize the store
          @min.times { @available.push(add_store) }

          loop do
            # Time to wait before there will be stores that should be closed
            ttl = if @ttl && @last_checkout && !@available.empty?
                    [@ttl - (Time.now - @last_checkout), 0].max
                  end

            # Time to wait
            timeout = if @timeout && !@waiting_since.empty?
                        longest_waiting = @waiting_since.first
                        [@timeout - (Time.now - longest_waiting), 0].max
                      end

            # Block until a message arrives, or until we time out for some reason
            wait = [ttl, timeout].compact.min
            if tuple = pop(wait)
              handle(tuple)
            end

            # If there are checkout requests that have been waiting too long,
            # feed them timeout errors.
            while @timeout && !@waiting.empty? && (Time.now - @waiting_since.first) >= @timeout
              waiting_since = @waiting_since.shift
              @waiting.shift.push(TimeoutError.new("Waited %<secs>f seconds" % { secs: Time.now - waiting_since }))
            end

            # If the last checkout was more than timeout ago, drop any available stores
            if @stopping || (@ttl && @last_checkout && Time.now - @last_checkout >= @ttl)
              while (@stopping || @stores.length > @min) and store = @available.pop
                store.close rescue nil
                @stores.delete(store)
              end
            end

            # Exit the loop if we are done
            break if @stopping && @stores.empty?
          end
        end
      end

      def push(message, what = nil, reply: false)
        raise ShutdownError, "Pool has been shutdown" if reply && !@thread.alive?
        queue = reply ? Queue.new : nil
        @mutex.synchronize do
          @inbox.push([message, what, queue])
          @resource.signal
        end
        queue.pop if queue
      end

      def pop(timeout = nil)
        @mutex.synchronize do
          @resource.wait(@mutex, timeout) if @inbox.empty?
          @inbox.shift
        end
      end

      def add_store
        store = @builder.build.last
        @stores.add(store)
        store
      end

      def handle_check_out(queue)
        @last_checkout = Time.now
        if @stopping
          queue.push(ShutdownError.new("Shutting down"))
        elsif !@available.empty?
          queue.push(@available.pop)
        elsif !@max || @stores.length < @max
          begin
            store = add_store
            queue.push(store)
          rescue => e
            queue.push(e)
          end
        else
          @waiting.push(queue)
          @waiting_since.push(Time.now) if @timeout
        end
      end

      def handle_stop
        @stopping = true
        # Reject anyone left waiting
        while queue = @waiting.shift
          queue.push(ShutdownError.new("Shutting down"))
        end
        @waiting_since = [] if @timeout
      end

      def handle_check_in(store)
        if !@waiting.empty?
          @waiting.shift.push(store)
          @waiting_since.shift if @timeout
        else
          @available.push(store)
        end
      end

      def handle_stats(reply)
        reply.push(stores: @stores.length,
                   available: @available.length,
                   waiting: @waiting.length,
                   longest_wait: @timeout && !@waiting_since.empty? ? @waiting_since.first.dup : nil,
                   stopping: @stopping,
                   last_checkout: @last_checkout && @last_checkout.dup)
      end

      def handle(request)
        cmd, what, reply = request
        case cmd
        when :check_out
          handle_check_out(reply)
        when :check_in
          # A checkin request
          handle_check_in(what)
        when :stats
          handle_stats(reply)
        when :stop
          # Graceful exit
          handle_stop
        end
      end
    end

    # @param [Hash] options
    # @option options [Integer] :min (0) The minimum pool size
    # @option options [Integer] :max The maximum pool size.  If not specified,
    #   there is no maximum.
    # @option options [Numeric] :ttl The number of seconds to keep
    #   stores above the minumum number around for without activity.  If
    #   not specified, stores will never be removed.
    # @option options [Numeric] :timeout The number of seconds to wait for a
    #   store to become available.  If not specified, will wait forever.
    # @yield A builder context for speciying how to construct stores
    def initialize(options = {}, &block)
      super(nil)
      @id = "Moneta::Pool(#{object_id})"
      @manager = PoolManager.new(Builder.new(&block), **options)
    end

    # Closing has no effect on the pool, as stores are closed in the background
    # by the manager after the ttl
    def close; end

    # Tells the manager to close all stores.  It will not be possible to use
    # the store after this.
    def stop
      @manager.stop
      nil
    end

    protected

    def adapter
      Thread.current.thread_variable_get(@id)
    end

    def adapter=(store)
      Thread.current.thread_variable_set(@id, store)
    end

    def wrap(*args, &block)
      if adapter
        yield
      else
        check_out!(&block)
      end
    end

    def check_out!
      store = @manager.check_out
      self.adapter = store
      yield
    ensure
      self.adapter = nil
      @manager.check_in store if store
    end
  end
end
