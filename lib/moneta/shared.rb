module Moneta
  # Shares a store between processes
  #
  # @example Share a store
  #   Moneta.build do
  #     use :Transformer, :key => :marshal, :value => :marshal
  #     use :Shared do
  #       adapter :GDBM, :file => 'shared.db'
  #     end
  #   end
  #
  # @api public
  class Shared < Wrapper
    # Constructor
    #
    # @param [Hash] options
    #
    # Options:
    # * :port - TCP port (default 9000)
    # * :host - Hostname (default empty)
    # * :file - Unix socket file name (default none)
    def initialize(options = {}, &block)
      @options = options
      @builder = Builder.new(&block)
    end

    def close
      if @server
        @server.stop
        @server = nil
      end
      if @adapter
        @adapter.close
        @adapter = nil
      end
    end

    private

    def wrap(*args)
      tries ||= 0
      @adapter ||= Adapters::Client.new(@options)
      yield
    rescue Exception => ex
      puts "Failed to connect: #{ex.message}"
      begin
        @adapter = Lock.new(@builder.build.last)
        @server = Server.new(@adapter, @options)
      rescue Exception => ex
        puts "Failed to start server: #{ex.message}"
        @adapter = nil
      end
      if (tries += 1) > 2
        raise
      else
        retry
      end
    end
  end
end
