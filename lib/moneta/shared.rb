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
  class Shared < Base
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

    def key?(key, options = {})
      with_adapter {|a| a.key?(key, options) }
    end

    def load(key, options = {})
      with_adapter {|a| a.load(key, options) }
    end

    def store(key, value, options = {})
      with_adapter {|a| a.store(key, value, options) }
      value
    end

    def delete(key, options = {})
      with_adapter {|a| a.delete(key, options) }
    end

    def clear(options = {})
      with_adapter {|a| a.clear(options) }
      self
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

    def with_adapter
      yield(@adapter ||= Adapters::Client.new(@options))
    rescue Exception => ex
      puts "Failed to connect: #{ex.message}"
      begin
        @adapter = Lock.new(@builder.build.last)
        @server = Server.new(@adapter, @options)
      rescue Exception => ex
        puts "Failed to start server: #{ex.message}"
        @adapter = nil
      end
      retry
    end
  end
end
