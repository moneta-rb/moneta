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
        @socket = options[:socket] ? UNIXSocket.open(options[:socket]) :
          TCPSocket.open(options[:host] || '127.0.0.1', options[:port] || 9000)
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        write(:key?, key, options)
        read
      end

      # (see Proxy#load)
      def load(key, options = {})
        write(:load, key, options)
        read
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        write(:store, key, value, options)
        read
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        write(:delete, key, options)
        read
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        write(:increment, key, amount, options)
        read
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        write(:create, key, value, options)
        read
      end

      # (see Proxy#clear)
      def clear(options = {})
        write(:clear, options)
        read
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
            read.freeze
          end
      end

      private

      def write(*args)
        s = Marshal.dump(args)
        @socket.write([s.bytesize].pack('N') << s)
      end

      def read
        size = @socket.read(4).unpack('N').first
        result = Marshal.load(@socket.read(size))
        raise result if Exception === result
        result
      end
    end
  end
end
