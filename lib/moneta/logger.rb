module Moneta
  # Logger proxy
  # @api public
  class Logger < Wrapper
    # Standard formatter used by the logger
    # @api public
    class Format
      def initialize(options)
        @prefix = options[:prefix] || 'Moneta '
        @out = options[:out] || STDOUT
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

    # @param [Moneta store] adapter The underlying store
    # @param [Hash] options
    # @option options [Object] :logger (Moneta::Logger::Format) Callable logger object
    # @option options [String] :logprefix ('Moneta ') Prefix string
    # @option options [IO] :logout (STDOUT) Output
    def initialize(adapter, options = {})
      super
      @logger = options[:logger] || Format.new(options)
    end

    protected

    def wrap(method, *args)
      ret = yield
      @logger.call(:method => method, :args => args, :return => (method == :clear ? 'self' : ret))
      ret
    rescue Exception => error
      @logger.call(:method => method, :args => args, :error => error)
      raise
    end
  end
end
