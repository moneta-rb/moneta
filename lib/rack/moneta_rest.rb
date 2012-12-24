require 'moneta'

module Rack
  class MonetaRest
    def initialize(store = nil, options = {}, &block)
      if block
        raise ArgumentError, 'Use either block or options' unless options.emtpy?
        @store = ::Moneta.build(&block)
      else
        raise ArgumentError, 'Option :store is required' unless @store = store
        @store = ::Moneta.new(@store, options) if Symbol === @store
      end
    end

    def call(env)
      key = env['PATH_INFO'][1..-1]
      case env['REQUEST_METHOD']
      when 'HEAD'
        if @store.key?(key)
          respond(200)
        else
          empty(404)
        end
      when 'GET'
        if value = @store[key]
          respond(200, value)
        else
          empty(404)
        end
      when 'POST', 'PUT'
        respond(200, @store[key] = env['rack.input'].read)
      when 'DELETE'
        if key.empty?
          @store.clear
          empty(200)
        else
          respond(200, @store.delete(key))
        end
      else
        empty(400)
      end
    rescue => ex
      respond(500, ex.message)
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
