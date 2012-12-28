require 'moneta'

module Rack
  class MonetaStore
    def initialize(app, store = nil, options = {}, &block)
      @app = app
      cache = options.delete(:cache)
      if block
        raise ArgumentError, 'Use either block or options' unless options.emtpy?
        @store = ::Moneta.build(&block)
      else
        raise ArgumentError, 'Option :store is required' unless @store = store
        @store = ::Moneta.new(@store, options) if Symbol === @store
      end
      if cache
        @cache = ::Moneta::Adapters::Memory.new
        @store = ::Moneta::Cache.new(:cache => @cache, :backend => @store)
      end
    end

    def call(env)
      env['rack.moneta'] = @store
      result = @app.call(env)
      @cache.clear if @cache
      result
    end
  end
end
