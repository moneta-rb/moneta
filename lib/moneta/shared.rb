require 'drb'

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
    # * :socket - Unix socket (default none)
    # * :uri - drbunix://socket or druby://host:port
    # * :table - Table name (default moneta)
    def initialize(options = {}, &block)
      options[:port] ||= 9000
      @uri = options[:uri] || (options[:socket] ? "drbunix://#{options[:socket]}" :
                               "druby://#{options[:host]}:#{options[:port]}")
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
        @adapter.close
        @server.stop_service
        @server = nil
      end
      @adapter = nil
    end

    private

    def with_adapter
      yield(@adapter ||= DRb::DRbObject.new(nil, @uri))
    rescue DRb::DRbConnError => ex
      puts ex.message
      begin
        @adapter = Lock.new(@builder.build.last)
        @server = DRb::DRbServer.new(@uri, @adapter)
      rescue Errno::EADDRINUSE => ex
        puts ex.message
        @adapter = nil
      end
      retry
    end
  end
end
