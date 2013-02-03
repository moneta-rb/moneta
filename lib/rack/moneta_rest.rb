require 'moneta'

module Rack
  # A Rack application which provides a REST interface to a Moneta store.
  #
  # @example config.ru
  #   map '/moneta' do
  #     run Rack::MonetaRest.new(:Memory)
  #   end
  #
  # @example config.ru
  #   # Pass it a block like the one passed to Moneta.build
  #   run Rack::MonetaRest.new do
  #     use :Transformer, :value => :zlib
  #     adapter :Memory
  #   end
  #
  # @api public
  class MonetaRest
    def initialize(store = nil, options = {}, &block)
      if block
        raise ArgumentError, 'Use either block or options' unless options.empty?
        @store = ::Moneta.build(&block)
      else
        raise ArgumentError, 'Block or argument store is required' unless @store = store
        @store = ::Moneta.new(@store, options) if Symbol === @store
      end
    end

    def call(env)
      key = env['PATH_INFO'][1..-1].to_s
      case env['REQUEST_METHOD']
      when 'HEAD'
        if key.empty?
          respond(400, 'Empty key')
        elsif @store.key?(key)
          empty(200)
        else
          empty(404)
        end
      when 'GET'
        if key.empty?
          respond(400, 'Empty key')
        elsif value = @store[key]
          respond(200, value)
        else
          empty(404)
        end
      when 'POST', 'PUT'
        if key.empty?
          respond(400, 'Empty key')
        else
          respond(200, @store[key] = env['rack.input'].read)
        end
      when 'DELETE'
        if key.empty?
          @store.clear
          empty(200)
        else
          respond(200, @store.delete(key))
        end
      else
        respond(400, 'Bad method')
      end
    rescue => ex
      respond(500, "Exception: #{ex.message}")
    end

    private

    def empty(status)
      [status, {'Content-Type'=>'application/octet-stream', 'Content-Length' => '0'}, []]
    end

    def respond(status, value)
      [status, {'Content-Type'=>'application/octet-stream', 'Content-Length' => value.bytesize.to_s}, [value]]
    end
  end
end
