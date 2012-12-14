require 'juno'
require 'rack/utils'

module Rack
  # A Rack middleware that was made to reuse all juno transformers
  # on the cookie hash.
  #
  # @example config.ru
  #   # Add Juno::Cookie somewhere in your rack stack
  #   use Juno::Cookie
  #
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
  #     adapter :Cookie
  #   end
  #
  #   run lambda{|env|
  #     req = Rack::Request.new(env)
  #     req.cookies #=> is now a Juno store!!
  #     req.cookies['key'] #=> retrieves 'juno.key'
  #     req.cookies['key'] = 'value' #=> sets 'juno.key'
  #     req.cookies.delete('key') #=> removes 'juno.key'
  #     [200,{},[]]
  #   }
  #
  class JunoCookies
    def initialize(app, options = {}, &block)
      @app = app
      if block
        raise 'Use either block or options' unless options.empty?
        @builder = Juno::Builder.new(&block)
      else
        @builder = Juno::Builder.new { adapter :Cookie, options }
      end
    end

    def call(env)
      stores = @builder.build
      env['rack.request.cookie_hash'] = stores.last
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
      [status, headers, body]
    end
  end
end
