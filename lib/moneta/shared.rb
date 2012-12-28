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
    # @param [Hash] options
    # @option options [Integer] :port (9000) TCP port
    # @option options [String] :host Server hostname
    # @option options [String] :file Unix socket file name
    def initialize(options = {}, &block)
      @options = options
      @builder = Builder.new(&block)
    end

    # (see Proxy#close)
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

    protected

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
