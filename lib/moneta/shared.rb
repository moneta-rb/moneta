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
        @thread.join
        @server = @thread = nil
      end
      if @adapter
        @adapter.close
        @adapter = nil
      end
    end

    private

    def wrap(*args)
      @adapter ||= Adapters::Client.new(@options)
      yield
    rescue Exception => ex
      puts "Failed to connect: #{ex.message}"
      begin
        # TODO: Implement this using forking (MRI) and threading (JRuby)
        # to get maximal performance
        @adapter = Lock.new(@builder.build.last)
        @server = Server.new(@adapter, @options)
        @thread = Thread.new { @server.run }
        sleep 0.1 until @server.running?
      rescue Exception => ex
        puts "Failed to start server: #{ex.message}"
        @adapter.close if @adapter
        @adapter = nil
      end
      tries ||= 0
      if (tries += 1) > 2
        raise
      else
        retry
      end
    end
  end
end
