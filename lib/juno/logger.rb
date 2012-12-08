module Juno
  # Logger proxy
  # @api public
  class Logger < Proxy
    # Standard formatter used by the logger
    # @api public
    class Format
      def initialize(options)
        @prefix = options[:logprefix] || 'Juno '
        @out = options[:logout] || STDOUT
      end

      def call(entry)
        @out.write(format(entry))
      end

      protected

      def format(entry)
        args = entry[:args]
        args.pop if Hash === args.last && args.last.empty?
        args = args.map {|a| dump(a) }.join(', ')
        if entry[:error]
          "#{@prefix}#{entry[:method]}(#{args}) raised error: #{entry[:error].message}\n"
        else
          "#{@prefix}#{entry[:method]}(#{args}) -> #{dump entry[:return]}\n"
        end
      end

      def dump(value)
        value = value.inspect
        value.size > 30 ? value[0..30] + '...' : value
      end
    end

    # Constructor
    #
    # @param [Juno store] adapter The underlying store
    # @param [Hash] options
    #
    # Options:
    # * :logger - Callable logger object (default Juno::Logger::Format)
    # * :logprefix - Prefix string (default 'Juno ')
    # * :logout - Output (default STDOUT)
    def initialize(adapter, options = {})
      super
      @logger = options[:logger] || Format.new(options)
    end

    def key?(key, options = {})
      log(:key?, key, options) { super }
    end

    def load(key, options = {})
      log(:load, key, options) { super }
    end

    def store(key, value, options = {})
      log(:store, key, value, options) { super }
    end

    def delete(key, options = {})
      log(:delete, key, options) { super }
    end

    def clear(options = {})
      log(:clear, options) { super; nil }
      self
    end

    def close
      log(:close) { super }
    end

    protected

    def log(method, *args)
      ret = yield
      @logger.call(:method => method, :args => args, :return => ret)
      ret
    rescue Exception => error
      @logger.call(:method => method, :args => args, :error => error)
      raise
    end
  end
end
