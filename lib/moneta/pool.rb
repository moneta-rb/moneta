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
    class Reply
      attr_reader :resource

      def initialize(mutex)
        @mutex = mutex
        @resource = ::ConditionVariable.new
        @value = nil
      end

      def resolve(value)
        @mutex.synchronize do
          raise "Already resolved" if @value
          @value = value
          @resource.signal
        end
        nil
      end

      def wait
        @resource.wait(@mutex)
        @value
      end
    end

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
        @thread = run
      end

      def stats
        push(:stats, reply: true)
      end

      def stop
        push(:stop)
        nil
      ensure
        @thread.value
      end

      def kill!
        @thread.kill
        nil
      end

      def check_out
        reply = push(:check_out, reply: true)
        raise reply if Exception === reply
        reply
      end

      def check_in(store)
        push(:check_in, store)
      end

      private

      def run
        Thread.new do
          begin
            populate_stores

            until @stopping && @stores.empty?
              # Block until a message arrives, or until we time out for some reason
              if request = pop
                handle_request(request)
              end

              # Handle any stale checkout requests
              handle_timed_out_requests
              # Drop any stores that are no longer needed
              remove_unneeded_stores
            end
          rescue => e
            reject_waiting(e.message)
            raise
          end
        end
      end

      def populate_stores
        return if @stopping
        @available.push(add_store) while @stores.length < @min
      end

      # If the last checkout was more than timeout ago, drop any available stores
      def remove_unneeded_stores
        return unless @stopping || (@ttl && @last_checkout && Time.now - @last_checkout >= @ttl)
        while (@stopping || @stores.length > @min) and store = @available.pop
          store.close rescue nil
          @stores.delete(store)
        end
      end

      # If there are checkout requests that have been waiting too long,
      # feed them timeout errors.
      def handle_timed_out_requests
        while @timeout && !@waiting.empty? && (Time.now - @waiting_since.first) >= @timeout
          waiting_since = @waiting_since.shift
          @waiting.shift.resolve(TimeoutError.new("Waited %<secs>f seconds" % { secs: Time.now - waiting_since }))
        end
      end

      # This is called from outside the loop thread
      def push(message, what = nil, reply: nil)
        @mutex.synchronize do
          raise ShutdownError, "Pool has been shutdown" if reply && !@thread.alive?
          reply &&= Reply.new(@mutex)
          @inbox.push([message, what, reply])
          @resource.signal
          reply.wait if reply
        end
      end

      # This method calculates the number of seconds to wait for a signal on
      # the condition variable, or `nil` if there is no need to time out.
      #
      # Calculated based on the `:ttl` and `:timeout` options used during
      # construction.
      #
      # @return [Integer, nil]
      def timeout
        # Time to wait before there will be stores that should be closed
        ttl = if @ttl && @last_checkout && !@available.empty?
                [@ttl - (Time.now - @last_checkout), 0].max
              end

        # Time to wait
        timeout = if @timeout && !@waiting_since.empty?
                    longest_waiting = @waiting_since.first
                    [@timeout - (Time.now - longest_waiting), 0].max
                  end

        [ttl, timeout].compact.min
      end

      def pop
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

      def handle_check_out(reply)
        @last_checkout = Time.now
        if @stopping
          reply.resolve(ShutdownError.new("Shutting down"))
        elsif !@available.empty?
          reply.resolve(@available.pop)
        elsif !@max || @stores.length < @max
          begin
            reply.resolve(add_store)
          rescue => e
            reply.resolve(e)
          end
        else
          @waiting.push(reply)
          @waiting_since.push(Time.now) if @timeout
        end
      end

      def handle_stop
        @stopping = true
        # Reject anyone left waiting
        reject_waiting "Shutting down"
      end

      def reject_waiting(reason)
        while reply = @waiting.shift
          reply.resolve(ShutdownError.new(reason))
        end
        @waiting_since = [] if @timeout
      end

      def handle_check_in(store)
        if !@waiting.empty?
          @waiting.shift.resolve(store)
          @waiting_since.shift if @timeout
        else
          @available.push(store)
        end
      end

      def handle_stats(reply)
        reply.resolve(stores: @stores.length,
                      available: @available.length,
                      waiting: @waiting.length,
                      longest_wait: @timeout && !@waiting_since.empty? ? @waiting_since.first.dup : nil,
                      stopping: @stopping,
                      last_checkout: @last_checkout && @last_checkout.dup)
      end

      def handle_request(request)
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

    def each_key(&block)
      wrap(:each_key) do
        raise NotImplementedError, "each_key is not supported on this proxy" \
          unless supports? :each_key

        return enum_for(:each_key) { adapter ? adapter.each_key.size : check_out! { adapter.each_key.size } } unless block_given?

        adapter.each_key(&block)
        self
      end
    end

    # Tells the manager to close all stores.  It will not be possible to use
    # the store after this.
    def stop
      @manager.stop
      nil
    end

    def stats
      @manager.stats
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
