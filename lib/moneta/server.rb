require 'socket'

module Moneta
  # Moneta server
  # @api public
  class Server
    # @param [Hash] options
    # @option options [Integer] :port (9000) TCP port
    # @option options [String] :file Alternative Unix socket file name
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

    # Is the server running
    #
    # @return [Boolean] true if the server is running
    def running?
      @running
    end

    # Run the server
    #
    # @note This method blocks!
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

    # Stop the server
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
      warn ex.message
      write(client, Error.new(ex.message)) if client
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
      when :key?, :load, :delete, :increment, :create
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
