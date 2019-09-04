require 'socket'

module Moneta
  module Adapters
    # Moneta client backend
    # @api public
    class Client
      include Defaults

      # @param [Hash] options
      # @option options [Integer] :port (9000) TCP port
      # @option options [String] :host ('127.0.0.1') Hostname
      # @option options [String] :socket Unix socket file name as alternative to `:port` and `:host`
      def initialize(options = {})
        @socket =
          if options[:socket]
            UNIXSocket.open(options[:socket])
          else
            TCPSocket.open(options[:host] || '127.0.0.1', options[:port] || 9000)
          end
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        write(:key?, key, options)
        read_msg
      end

      # (see Proxy#load)
      def load(key, options = {})
        write(:load, key, options)
        read_msg
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        write(:store, key, value, options)
        read_msg
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        write(:delete, key, options)
        read_msg
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        write(:increment, key, amount, options)
        read_msg
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        write(:create, key, value, options)
        read_msg
      end

      # (see Proxy#clear)
      def clear(options = {})
        write(:clear, options)
        read_msg
        self
      end

      # (see Proxy#close)
      def close
        @socket.close
        nil
      end

      # (see Default#features)
      def features
        @features ||=
          begin
            write(:features)
            read_msg.freeze
          end
      end

      private

      def write(*args)
        s = Marshal.dump(args)
        @socket.write([s.bytesize].pack('N') << s)
      end

      # JRuby doesn't support socket#recv with flags
      if defined?(JRUBY_VERSION)
        def read(bytes)
          received = @socket.read(bytes)
          raise EOFError, "Server closed socket" unless received && received.bytesize == bytes
          received
        end
      else
        def read(bytes)
          received = @socket.recv(bytes, Socket::MSG_WAITALL)
          raise EOFError, "Server closed socket" unless received && received.bytesize == bytes
          received
        end
      end

      def read_msg
        size = read(4).unpack('N').first
        result = Marshal.load(read(size))
        raise result if Exception === result
        result
      end
    end
  end
end
