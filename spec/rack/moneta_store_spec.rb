require 'helper'
require 'rack/mock'
require 'rack/moneta_store'

describe Rack::MonetaStore do
  def config(store_arg = nil, options = nil, &block)
    @store_arg = store_arg
    @options = options
    @block = block
  end

  def app(&block)
    @app_block ||= block
  end

  def middleware
    @middleware ||= Rack::MonetaStore.new(lambda do |env|
      @store = env['rack.moneta_store']
      app.call(env) if app
      [200,{},[]]
    end, @store_arg, @options || {}, &@block)
  end

  def backend
    @backend ||= Rack::MockRequest.new(middleware)
  end

  def get(&block)
    app(&block)
    @response = backend.get('/')
  end

  def uncached_store
    middleware.instance_variable_get(:@store)
  end

  it 'should be able to get a key without caching' do
    config :Memory
    uncached_store['key'] = 'value'
    get do
      expect(@store['key']).to eql('value')
    end
  end

  it 'should be able to get a key with caching' do
    config :Memory, :cache => true
    uncached_store['key'] = 'value'
    get do
      expect(@store['key']).to eql('value')
      expect(@store.adapter).to equal(uncached_store)
      expect(@store.cache['key']).to eql('value')
    end
  end

  it 'should be able to set a key' do
    config :Memory
    get do
      @store['key'] = 'value'
    end
    expect( @store['key'] ).to eql('value')
    expect(uncached_store['key']).to eql('value')
  end

  it 'should be able to get a remove a key' do
    config :Memory
    uncached_store['key'] = 'value'
    get do
      expect(@store.delete('key')).to eql('value')
    end
    expect(uncached_store.key?('key')).to be_false
  end

  it 'should accept a config block' do
    config do
      use :Transformer, :key => :prefix, :prefix => 'moneta.'
      adapter :Memory
    end
    uncached_store['key'] = 'value'
    get do
      expect(@store['key']).to eql('value')
    end
  end
end
