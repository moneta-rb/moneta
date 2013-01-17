require 'moneta'
require 'rack/utils'

module Rack
  # A Rack middleware that was made to reuse all moneta transformers
  # on the cookie hash.
  #
  # @example config.ru
  #   # Add Rack::MonetaCookies somewhere in your rack stack
  #   use Rack::MonetaCookies
  #
  #   run lambda { |env| [200, {}, []] }
  #   # But this doesn't do much
  #
  # @example config.ru
  #   # Give it some options
  #   use Rack::MonetaCookies, :domain => 'example.com', :path => '/path'
  #
  # @example config.ru
  #   # Pass it a block like the one passed to Moneta.build
  #   use Rack::MonetaCookies do
  #     use :Transformer, :key => :prefix, :prefix => 'moneta.'
  #     adapter :Cookie
  #   end
  #
  #   run lambda { |env|
  #     req = Rack::Request.new(env)
  #     req.cookies #=> is now a Moneta store!
  #     env['rack.request.cookie_hash'] #=> is now a Moneta store!
  #     req.cookies['key'] #=> retrieves 'moneta.key'
  #     req.cookies['key'] = 'value' #=> sets 'moneta.key'
  #     req.cookies.delete('key') #=> removes 'moneta.key'
  #     [200, {}, []]
  #   }
  #
  # @api public
  class MonetaCookies
    def initialize(app, options = {}, &block)
      @app, @pool = app, []
      if block
        raise ArgumentError, 'Use either block or options' unless options.empty?
        @builder = Moneta::Builder.new(&block)
      else
        @builder = Moneta::Builder.new { adapter :Cookie, options }
      end
    end

    def call(env)
      stores = @pool.pop || @builder.build
      env['rack.moneta_cookies'] = env['rack.request.cookie_hash'] = stores.last
      env['rack.request.cookie_string'] = env['HTTP_COOKIE']
      stores.first.reset(Rack::Utils.parse_query(env['HTTP_COOKIE']))
      status, headers, body = @app.call(env)
      stores.first.cookies.each do |key, cookie|
        if cookie == nil
          Rack::Utils.delete_cookie_header!(headers, key)
        else
          Rack::Utils.set_cookie_header!(headers, key, cookie)
        end
      end
      @pool << stores
      [status, headers, body]
    end
  end
end
