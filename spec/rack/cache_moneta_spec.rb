require 'rack/cache/moneta'
require 'rack/mock'
require 'rack/cache'

class Object
  def sha_like?
    length == 40 && self =~ /^[0-9a-z]+$/
  end
end

describe Rack::Cache::MetaStore::Moneta do
  before do
    Rack::Cache::Moneta['meta'] = Moneta.new(:Memory, :expires => true)
    Rack::Cache::Moneta['entity'] = Moneta.new(:Memory, :expires => true)
    @store        = Rack::Cache::MetaStore::Moneta.resolve   uri('moneta://entity')
    @entity_store = Rack::Cache::EntityStore::Moneta.resolve uri('moneta://meta')
    @request  = mock_request('/', {})
    @response = mock_response(200, {}, ['hello world'])
  end

  after do
    Rack::Cache::Moneta['meta'].clear
    Rack::Cache::Moneta['entity'].clear
  end

  it "has the class referenced by homonym constant" do
    Rack::Cache::MetaStore::MONETA.should == Rack::Cache::MetaStore::Moneta
  end

  it "instantiates the store" do
    @store.should be_kind_of(Rack::Cache::MetaStore::Moneta)
  end

  it "resolves the connection uri" do
    Rack::Cache::MetaStore::Moneta.resolve(uri('moneta://Memory?expires=true')).should be_kind_of(Rack::Cache::MetaStore::Moneta)
  end

  # Low-level implementation methods ===========================================

  it 'writes a list of negotation tuples with #write' do
    # lambda {
    @store.write('/test', [[{}, {}]])
    # }.should_not raise Exception
  end

  it 'reads a list of negotation tuples with #read' do
    @store.write('/test', [[{},{}],[{},{}]])
    tuples = @store.read('/test')
    tuples.should == [ [{},{}], [{},{}] ]
  end

  it 'reads an empty list with #read when nothing cached at key' do
    @store.read('/nothing').should be_empty
  end

  it 'removes entries for key with #purge' do
    @store.write('/test', [[{},{}]])
    @store.read('/test').should_not be_empty

    @store.purge('/test')
    @store.read('/test').should be_empty
  end

  it 'succeeds when purging non-existing entries' do
    @store.read('/test').should be_empty
    @store.purge('/test')
  end

  it 'returns nil from #purge' do
    @store.write('/test', [[{},{}]])
    @store.purge('/test').should be_nil
    @store.read('/test').should == []
  end

  %w[/test http://example.com:8080/ /test?x=y /test?x=y&p=q].each do |key|
    it "can read and write key: '#{key}'" do
      # lambda {
      @store.write(key, [[{},{}]])
      # }.should_not raise Exception
      @store.read(key).should == [[{},{}]]
    end
  end

  it "can read and write fairly large keys" do
    key = "b" * 4096
    # lambda {
    @store.write(key, [[{},{}]])
    # }.should_not raise Exception
    @store.read(key).should == [[{},{}]]
  end

  it "allows custom cache keys from block" do
    request = mock_request('/test', {})
    request.env['rack-cache.cache_key'] =
      lambda { |request| request.path_info.reverse }
    @store.cache_key(request).should == 'tset/'
  end

  it "allows custom cache keys from class" do
    request = mock_request('/test', {})
    request.env['rack-cache.cache_key'] = Class.new do
      def self.call(request); request.path_info.reverse end
    end
    @store.cache_key(request).should == 'tset/'
  end

  it 'does not blow up when given a non-marhsalable object with an ALL_CAPS key' do
    store_simple_entry('/bad', { 'SOME_THING' => Proc.new {} })
  end

  # Abstract methods ===========================================================

  it 'stores a cache entry' do
    cache_key = store_simple_entry
    @store.read(cache_key).should_not be_empty
  end

  it 'sets the X-Content-Digest response header before storing' do
    cache_key = store_simple_entry
    req, res = @store.read(cache_key).first
    res['X-Content-Digest'].should == 'a94a8fe5ccb19ba61c4c0873d391e987982fbbd3'
  end

  it 'finds a stored entry with #lookup' do
    store_simple_entry
    response = @store.lookup(@request, @entity_store)
    response.should_not be_nil
    response.should be_kind_of(Rack::Cache::Response)
  end

  it 'does not find an entry with #lookup when none exists' do
    req = mock_request('/test', {'HTTP_FOO' => 'Foo', 'HTTP_BAR' => 'Bar'})
    @store.lookup(req, @entity_store).should be_nil
  end

  it "canonizes urls for cache keys" do
    store_simple_entry(path='/test?x=y&p=q')

    hits_req = mock_request(path, {})
    miss_req = mock_request('/test?p=x', {})

    @store.lookup(hits_req, @entity_store).should_not be_nil
    @store.lookup(miss_req, @entity_store).should be_nil
  end

  it 'does not find an entry with #lookup when the body does not exist' do
    store_simple_entry
    @response.headers['X-Content-Digest'].should_not be_nil
    @entity_store.purge(@response.headers['X-Content-Digest'])
    @store.lookup(@request, @entity_store).should be_nil
  end

  it 'restores response headers properly with #lookup' do
    store_simple_entry
    response = @store.lookup(@request, @entity_store)
    response.headers.should == @response.headers.merge('Content-Length' => '4')
  end

  it 'restores response body from entity store with #lookup' do
    store_simple_entry
    response = @store.lookup(@request, @entity_store)
    body = '' ; response.body.each {|p| body << p}
    body.should == 'test'
  end

  it 'invalidates meta and entity store entries with #invalidate' do
    store_simple_entry
    @store.invalidate(@request, @entity_store)
    response = @store.lookup(@request, @entity_store)
    response.should be_kind_of(Rack::Cache::Response)
    response.should_not be :fresh?
  end

  it 'succeeds quietly when #invalidate called with no matching entries' do
    req = mock_request('/test', {})
    @store.invalidate(req, @entity_store)
    @store.lookup(@request, @entity_store).should be_nil
  end

  # Vary =======================================================================

  it 'does not return entries that Vary with #lookup' do
    req1 = mock_request('/test', {'HTTP_FOO' => 'Foo', 'HTTP_BAR' => 'Bar'})
    req2 = mock_request('/test', {'HTTP_FOO' => 'Bling', 'HTTP_BAR' => 'Bam'})
    res = mock_response(200, {'Vary' => 'Foo Bar'}, ['test'])
    @store.store(req1, res, @entity_store)

    @store.lookup(req2, @entity_store).should be_nil
  end

  it 'stores multiple responses for each Vary combination' do
    req1 = mock_request('/test', {'HTTP_FOO' => 'Foo',   'HTTP_BAR' => 'Bar'})
    res1 = mock_response(200, {'Vary' => 'Foo Bar'}, ['test 1'])
    key = @store.store(req1, res1, @entity_store)

    req2 = mock_request('/test', {'HTTP_FOO' => 'Bling', 'HTTP_BAR' => 'Bam'})
    res2 = mock_response(200, {'Vary' => 'Foo Bar'}, ['test 2'])
    @store.store(req2, res2, @entity_store)

    req3 = mock_request('/test', {'HTTP_FOO' => 'Baz',   'HTTP_BAR' => 'Boom'})
    res3 = mock_response(200, {'Vary' => 'Foo Bar'}, ['test 3'])
    @store.store(req3, res3, @entity_store)

    slurp(@store.lookup(req3, @entity_store).body).should == 'test 3'
    slurp(@store.lookup(req1, @entity_store).body).should == 'test 1'
    slurp(@store.lookup(req2, @entity_store).body).should == 'test 2'

    @store.read(key).length.should == 3
  end

  it 'overwrites non-varying responses with #store' do
    req1 = mock_request('/test', {'HTTP_FOO' => 'Foo',   'HTTP_BAR' => 'Bar'})
    res1 = mock_response(200, {'Vary' => 'Foo Bar'}, ['test 1'])
    key = @store.store(req1, res1, @entity_store)
    slurp(@store.lookup(req1, @entity_store).body).should == 'test 1'

    req2 = mock_request('/test', {'HTTP_FOO' => 'Bling', 'HTTP_BAR' => 'Bam'})
    res2 = mock_response(200, {'Vary' => 'Foo Bar'}, ['test 2'])
    @store.store(req2, res2, @entity_store)
    slurp(@store.lookup(req2, @entity_store).body).should == 'test 2'

    req3 = mock_request('/test', {'HTTP_FOO' => 'Foo',   'HTTP_BAR' => 'Bar'})
    res3 = mock_response(200, {'Vary' => 'Foo Bar'}, ['test 3'])
    @store.store(req3, res3, @entity_store)
    slurp(@store.lookup(req1, @entity_store).body).should == 'test 3'

    @store.read(key).length.should == 2
  end

  private
  def mock_request(uri, opts)
    env = Rack::MockRequest.env_for(uri, opts || {})
    Rack::Cache::Request.new(env)
  end

  def mock_response(status, headers, body)
    headers ||= {}
    body = Array(body).compact
    Rack::Cache::Response.new(status, headers, body)
  end

  def slurp(body)
    buf = ''
    body.each { |part| buf << part }
    buf
  end

  # Stores an entry for the given request args, returns a url encoded cache key
  # for the request.
  def store_simple_entry(*request_args)
    path, headers = request_args
    @request = mock_request(path || '/test', headers || {})
    @response = mock_response(200, {'Cache-Control' => 'max-age=420'}, ['test'])
    body = @response.body
    cache_key = @store.store(@request, @response, @entity_store)
    @response.body.should == body
    cache_key
  end

  def uri(uri)
    URI.parse uri
  end
end

describe Rack::Cache::EntityStore::Moneta do
  before do
    @store = Rack::Cache::EntityStore::Moneta.resolve(uri('moneta://Memory?expires=true'))
  end

  it 'has the class referenced by homonym constant' do
    Rack::Cache::EntityStore::MONETA.should == Rack::Cache::EntityStore::Moneta
  end

  it 'resolves the connection uri' do
    Rack::Cache::EntityStore::Moneta.resolve(uri('moneta://Memory?expires=true')).should be_kind_of(Rack::Cache::EntityStore::Moneta)
  end

  it 'responds to all required messages' do
    %w[read open write exist?].each do |message|
      @store.should respond_to message
    end
  end

  it 'stores bodies with #write' do
    key, size = @store.write(['My wild love went riding,'])
    key.should_not be_nil
    key.should be_sha_like

    data = @store.read(key)
    data.should == 'My wild love went riding,'
  end

  it 'takes a ttl parameter for #write' do
    key, size = @store.write(['My wild love went riding,'], 0)
    key.should_not be_nil
    key.should be_sha_like

    data = @store.read(key)
    data.should == 'My wild love went riding,'
  end

  it 'correctly determines whether cached body exists for key with #exist?' do
    key, size = @store.write(['She rode to the devil,'])
    @store.exist?(key).should be_true
    @store.exist?('938jasddj83jasdh4438021ksdfjsdfjsdsf').should be_false
  end

  it 'can read data written with #write' do
    key, size = @store.write(['And asked him to pay.'])
    data = @store.read(key)
    data.should == 'And asked him to pay.'
  end

  it 'gives a 40 character SHA1 hex digest from #write' do
    key, size = @store.write(['she rode to the sea;'])
    key.should_not be_nil
    key.length.should == 40
    key.should match(/^[0-9a-z]+$/)
    key.should == '90a4c84d51a277f3dafc34693ca264531b9f51b6'
  end

  it 'returns the entire body as a String from #read' do
    key, size = @store.write(['She gathered together'])
    @store.read(key).should == 'She gathered together'
  end

  it 'returns nil from #read when key does not exist' do
    @store.read('87fe0a1ae82a518592f6b12b0183e950b4541c62').should be_nil
  end

  it 'returns a Rack compatible body from #open' do
    key, size = @store.write(['Some shells for her hair.'])
    body = @store.open(key)
    body.should respond_to :each
    buf = ''
    body.each { |part| buf << part }
    buf.should == 'Some shells for her hair.'
  end

  it 'returns nil from #open when key does not exist' do
    @store.open('87fe0a1ae82a518592f6b12b0183e950b4541c62').should be_nil
  end

  it 'deletes stored entries with #purge' do
    key, size = @store.write(['My wild love went riding,'])
    @store.purge(key).should be_nil
    @store.read(key).should be_nil
  end

  private

  def uri(uri)
    URI.parse uri
  end
end
