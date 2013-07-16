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
    # @option options [String] :socket Unix socket file name
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
      connect
      yield
    end

    def connect
      @adapter ||= Adapters::Client.new(@options)
    rescue Errno::ECONNREFUSED, Errno::ENOENT => ex
      start_server
      tries ||= 0
      warn "Moneta::Shared - Failed to connect: #{ex.message}" if tries > 0
      (tries += 1) < 3 ? retry : raise
    end

    # TODO: Implement this using forking (MRI) and threading (JRuby)
    # to get maximal performance
    def start_server
      @adapter = Lock.new(@builder.build.last)
      @server = Server.new(@adapter, @options)
      @thread = Thread.new { @server.run }
      sleep 0.1 until @server.running?
    rescue Exception => ex
      @adapter.close if @adapter
      @adapter = nil
      @server = nil
      @thread = nil
      warn "Moneta::Shared - Failed to start server: #{ex.message}"
    end
  end
end
