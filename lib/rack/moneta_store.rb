require 'moneta'

module Rack
  # A Rack middleware that inserts a Moneta store in the environment
  # and supports per request caching via the the option `:cache => true`.
  #
  # @example config.ru
  #   # Add Rack::MonetaStore somewhere in your rack stack
  #   use Rack::MonetaStore, :Memory, :cache => true
  #
  #   run lambda do |env|
  #     env['rack.moneta_store'] # is a Moneta store with per request caching
  #   end
  #
  # @example config.ru
  #   # Pass it a block like the one passed to Moneta.build
  #   use Rack::MonetaStore do
  #     use :Transformer, :value => :zlib
  #     adapter :Cookie
  #   end
  #
  #   run lambda do |env|
  #     env['rack.moneta_store'] # is a Moneta store without caching
  #   end
  #
  # @api public
  class MonetaStore
    def initialize(app, store = nil, options = {}, &block)
      @app = app
      @cache = options.delete(:cache)
      if block
        raise ArgumentError, 'Use either block or options' unless options.emtpy?
        @store = ::Moneta.build(&block)
      else
        raise ArgumentError, 'Option :store is required' unless @store = store
        @store = ::Moneta.new(@store, options) if Symbol === @store
      end
    end

    def call(env)
      env['rack.moneta_store'] = @cache ? ::Moneta::Cache.new(:cache => ::Moneta::Adapters::Memory.new, :backend => @store) : @store
      @app.call(env)
    end
  end
end
