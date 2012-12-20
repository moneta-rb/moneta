require 'socket'

module Moneta
  # Moneta server
  # @api public
  class Server
    DEFAULT_PORT = 9000
    TIMEOUT = 1

    module Util
      def read(io)
        size = io.read(4).unpack('N').first
        Marshal.load(io.read(size))
      end

      def write(io, o)
        s = Marshal.dump(o)
        io.write([s.bytesize].pack('N') << s)
      end
    end

    include Util

    # Constructor
    #
    # @param [Hash] options
    #
    # Options:
    # * :port - TCP port (default 9000)
    # * :host - Hostname (default empty)
    # * :file - Unix socket file name (default none)
    def initialize(store, options = {})
      @store = store
      @server = options[:file] ? UNIXServer.open(options[:file]) :
        TCPServer.open(options[:port] || DEFAULT_PORT)
      @clients = [@server]
      @running = true
      @thread = Thread.new do
        mainloop while @running
        File.unlink(options[:file]) if options[:file]
      end
    end

    def stop
      if @thread
        @running = false
        @server.close
        @server = nil
        @thread.join
        @thread = nil
      end
    end

    private

    def mainloop
      client = accept
      handle(client) if client
    rescue Exception => ex
      puts "#{ex.message}\n#{ex.backtrace.join("\n")}"
      if client
        client.close
        @clients.delete(client)
      end
    end

    def accept
      ios = IO.select(@clients, nil, @clients, TIMEOUT)
      return nil unless ios
      ios[2].each do |io|
        io.close
        @clients.delete(io)
      end
      ios[0].each do |io|
        if io == @server
          client = @server.accept
          @clients << client if client
        else
          return io unless io.eof?
          @clients.delete(io)
        end
      end
      nil
    end

    def handle(client)
      method, *args = read(client)
      case method
      when :key?, :load, :delete
        write(client, @store.send(method, *args))
      when :store, :clear
        @store.send(method, *args)
      else
        raise 'Invalid method call'
      end
    end
  end
end
