require 'socket'

module Moneta
  # Moneta server
  # @api public
  class Server
    # Constructor
    #
    # @param [Hash] options
    #
    # Options:
    # * :port - TCP port (default 9000)
    # * :file - Unix socket file name (default none)
    def initialize(store, options = {})
      @store = store
      @server =
        if @file = options[:file]
          UNIXServer.open(@file)
        else
          TCPServer.open(options[:port] || DEFAULT_PORT)
        end
      @clients = [@server]
      @running = false
    end

    def running?
      @running
    end

    def run
      raise 'Already running' if @running
      @stop = false
      @running = true
      begin
        until @stop
          mainloop
        end
      ensure
        File.unlink(@file) if @file
      end
    end

    def stop
      raise 'Not running' unless @running
      @stop = true
      @server.close
      @server = nil
    end

    private

    include Net
    TIMEOUT = 1

    def mainloop
      client = accept
      handle(client) if client
    rescue Exception => ex
      puts "#{ex.message}\n#{ex.backtrace.join("\n")}"
      write(client, Exception.new(ex.message)) if client
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
      when :key?, :load, :delete, :increment
        write(client, @store.send(method, *args))
      when :store, :clear
        @store.send(method, *args)
        client.write(@nil ||= pack(nil))
      else
        raise 'Invalid method call'
      end
    end
  end
end
