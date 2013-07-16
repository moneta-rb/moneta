module Moneta
  # Logger proxy
  # @api public
  class Logger < Wrapper
    # Standard formatter used by the logger
    # @api public
    class Format
      def initialize(options)
        @prefix = options[:prefix] || 'Moneta '
        if options[:file]
          @close = true
          @out = File.open(options[:file], 'a')
        else
          @close = options[:close]
          @out = options[:out] || STDOUT
        end
      end

      def log(entry)
        @out.write(format(entry))
      end

      def close
        @out.close if @close
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
    # @option options [Object] :logger (Moneta::Logger::Format) Logger object
    # @option options [String] :prefix ('Moneta ') Prefix string
    # @option options [File] :file Log file
    # @option options [IO] :out (STDOUT) Output
    def initialize(adapter, options = {})
      super
      @logger = options[:logger] || Format.new(options)
    end

    def close
      super
      @logger.close
      nil
    end

    protected

    def wrap(method, *args)
      ret = yield
      @logger.log(:method => method, :args => args, :return => (method == :clear ? 'self' : ret))
      ret
    rescue Exception => error
      @logger.log(:method => method, :args => args, :error => error)
      raise
    end
  end
end
