require 'helper'
require 'rack/mock'

describe Juno::Cookie do

  attr :response, :store

  def config(options={},&block)
    @options = options
    @block = block
  end

  def app(&block)
    @app_block ||= block
  end

  def backend
    Rack::MockRequest.new(Juno::Cookie.new(lambda{|env|
      @store = env['rack.request.cookie_hash']
      app.call(env) if app
      [200,{},[]]
    }, @options || {}, &@block))
  end

  def get(cookies = {}, &block)
    app(&block)
    @response = backend.get('/','HTTP_COOKIE' => Rack::Utils.build_query(cookies))
  end

  it 'should be able to read a simple key' do
    get 'key' => 'value' do
      expect( store['key'] ).to eql('value')
    end
  end

  it 'should be able to set a simple key' do
    get do
      store['key'] = 'value'
    end
    expect( response['Set-Cookie'] ).to eql('key=value')
  end

  it 'should be able to remove a simple key' do
    get 'key' => 'value' do
      store.delete('key')
    end
    expect( response['Set-Cookie'] ).to eql('key=; expires=Thu, 01-Jan-1970 00:00:00 GMT')
  end

  it 'should accept a config block' do
    config do
      use :Transformer, :key => :prefix, :prefix => 'juno.'
    end
    get 'juno.key' => 'right', 'key' => 'wrong' do
      expect( store['key'] ).to eql('right')
    end
  end

  it 'should accept a :domain option' do
    config :domain => 'example.com'
    get do
      store['key'] = 'value'
    end
    expect(response['Set-Cookie']).to eql('key=value; domain=example.com')
  end

  it 'should accept a :path option' do
    config :path => '/path'
    get do
      store['key'] = 'value'
    end
    expect(response['Set-Cookie']).to eql('key=value; path=/path')
  end

  it 'should be accessible via Rack::Request' do
    get 'key' => 'value' do |env|
      req = Rack::Request.new(env)
      expect(req.cookies['key']).to eql('value')
    end
  end

end
