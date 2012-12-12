module Juno

  # A Rack middleware that was made to reuse all juno transformers 
  # on the cookie hash.
  #
  # @example config.ru
  #   # Add Juno::Cookie somewhere in your rack stack
  #   use Juno::Cookie
  #   …
  #   run lambda{|env| [200,{},[]] }
  #   # But this doesn't do much
  #
  # @example config.ru
  #   # Give it some options
  #   use Juno::Cookie, :domain => 'example.com', :path => '/path'
  #
  # @example config.ru
  #   # Pass it a block like the one passed to Juno.build
  #   use Juno::Cookie do
  #     use :Transformer, :key => :prefix, :prefix => 'juno.'
  #     # Note: no adapter given here
  #   end
  #   …
  #   run lambda{|env|
  #     req = Rack::Request.new(env)
  #     req.cookies #=> is now a Juno store!!
  #     req.cookies['key'] #=> retrieves 'juno.key'
  #     req.cookies['key'] = 'value' #=> sets 'juno.key'
  #     req.cookies.delete('key') #=> removes 'juno.key'
  #     [200,{},[]]
  #   }
  #
  class Cookie

    # @api private
    class Builder < Juno::Builder

      # @api private
      class NewInterceptor

        attr :object

        def initialize(klass)
          @klass = klass
        end

        def new(*args)
          @object = @klass.new(*args)
        end

      end

      attr :adapter_called

      def build
        interceptor = @proxies[0][0] = NewInterceptor.new(@proxies[0][0])
        result = super
        return result, interceptor.object
      end

      def adapter(*args)
        @adapter_called = true
        super
      end

    end

    # @param [#call] app a rack application
    # @param [Hash] options an option hash which will be passed to Juno::Adapter::Cookie
    def initialize(app, options = {}, &block)
      @app = app
      block ||= lambda{|_|}
      @builder = Builder.new(&block)
      if !@builder.adapter_called
        @builder.adapter(:Cookie, options)
      end
    end

    def call(env)
      env["rack.request.cookie_hash"], backend = @builder.build
      backend.parse( env['HTTP_COOKIE'] )
      env['rack.request.cookie_string'] = env['HTTP_COOKIE']
      status, headers, body = @app.call(env)
      backend.unparse(headers)
      return status, headers, body
    end

  end

end
