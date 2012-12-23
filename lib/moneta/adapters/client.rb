require 'socket'

module Moneta
  module Adapters
    # Moneta client backend
    # @api public
    class Client < Base
      include Net

      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :port - TCP port (default 9000)
      # * :host - Hostname (default empty)
      # * :file - Unix socket file name (default none)
      def initialize(options = {})
        @socket = options[:file] ? UNIXSocket.open(options[:file]) :
          TCPSocket.open(options[:host] || '127.0.0.1', options[:port] || DEFAULT_PORT)
      end

      def key?(key, options = {})
        write(@socket, [:key?, key, options])
        read_result
      end

      def load(key, options = {})
        write(@socket, [:load, key, options])
        read_result
      end

      def store(key, value, options = {})
        write(@socket, [:store, key, value, options])
        read_result
        value
      end

      def delete(key, options = {})
        write(@socket, [:delete, key, options])
        read_result
      end

      def increment(key, amount = 1, options = {})
        write(@socket, [:increment, key, amount, options])
        read_result
      end

      def clear(options = {})
        write(@socket, [:clear, options])
        read_result
        self
      end

      def close
        @socket.close
        nil
      end

      private

      def read_result
        result = read(@socket)
        raise result if Exception === result
        result
      end
    end
  end
end
