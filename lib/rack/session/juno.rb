require 'juno'
require 'rack/session/abstract/id'
require 'thread'

module Rack
  module Session
    class Juno < Abstract::ID
      attr_reader :mutex, :pool

      def initialize(app, options = {}, &block)
        super
        if block
          raise ArgumentError, 'Use either block or option :store' if options[:store]
          @pool = ::Juno.build(&block)
        else
          raise ArgumentError, 'Option :store is required' unless @pool = options[:store]
          @pool = ::Juno.new(@pool, :expires => true) if Symbol === @pool
        end
        @mutex = Mutex.new
      end

      def generate_sid
        loop do
          sid = super
          break sid unless @pool.key?(sid)
        end
      end

      def get_session(env, sid)
        with_lock(env) do
          unless sid && session = @pool[sid]
            sid, session = generate_sid, {}
            @pool[sid] = session
          end
          [sid, session]
        end
      end

      def set_session(env, session_id, new_session, options)
        with_lock(env) do
          @pool.store(session_id, new_session,
                       options[:expire_after] ? {:expires => options[:expire_after]} : {})
          session_id
        end
      end

      def destroy_session(env, session_id, options)
        with_lock(env) do
          @pool.delete(session_id)
          generate_sid unless options[:drop]
        end
      end

      def with_lock(env)
        @mutex.lock if env['rack.multithread']
        yield
      ensure
        @mutex.unlock if @mutex.locked?
      end
    end
  end
end

