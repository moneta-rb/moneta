ADAPTER_SPECS = [:null_stringkey_stringvalue, :store_stringkey_stringvalue, :returndifferent_stringkey_stringvalue]
SIMPLE_SPECS = [:null, :store, :returndifferent, :marshallable_key]
EXPIRES_SPECS = SIMPLE_SPECS + [:expires_stringkey_stringvalue]

TESTS = {
  'simple_memory' => {
    :store => :Memory
  },
  'simple_file' => {
    :store => :File,
    :options => ':dir => File.join(make_tempdir, "simple_file")'
  },
  'simple_hashfile' => {
    :store => :HashFile,
    :options => ':dir => File.join(make_tempdir, "simple_hashfile")'
  },
  'simple_cassandra' => {
    :store => :Cassandra,
    :specs => EXPIRES_SPECS,
  },
  'simple_dbm' => {
    :store => :DBM,
    :options => ':file => File.join(make_tempdir, "simple_dbm")'
  },
  'simple_gdbm' => {
    :store => :GDBM,
    :options => ':file => File.join(make_tempdir, "simple_gdbm")'
  },
  'simple_sdbm' => {
    :store => :SDBM,
    :options => ':file => File.join(make_tempdir, "simple_sdbm")'
  },
  'simple_pstore' => {
    :store => :PStore,
    :options => ':file => File.join(make_tempdir, "simple_pstore")'
  },
  'simple_yaml' => {
    :store => :YAML,
    :options => ':file => File.join(make_tempdir, "simple_yaml")'
  },
  'simple_localmemcache' => {
    :store => :LocalMemCache,
    :options => ':file => File.join(make_tempdir, "simple_localmemcache")'
  },
  'simple_tokyocabinet' => {
    :store => :TokyoCabinet,
    :options => ':file => File.join(make_tempdir, "simple_tokyocabinet")'
  },
  'simple_sqlite' => {
    :store => :Sqlite,
    :options => ':file => ":memory:"'
  },
  'simple_redis' => {
    :store => :Redis,
    :specs => EXPIRES_SPECS,
  },
  'simple_memcached' => {
    :store => :Memcached,
    :specs => EXPIRES_SPECS,
    :options => ':server => "localhost:22122", :namespace => "simple_memcached"'
  },
  'simple_memcached_dalli' => {
    :store => :MemcachedDalli,
    :specs => EXPIRES_SPECS,
    :options => ':server => "localhost:22122", :namespace => "simple_memcached_dalli"'
  },
  'simple_memcached_native' => {
    :store => :MemcachedNative,
    :specs => EXPIRES_SPECS,
    :options => ':server => "localhost:22122", :namespace => "simple_memcached_native"'
  },
  'simple_riak' => {
    :store => :Riak,
    :options => ":bucket => 'simple_riak'",
    # We don't want Riak warnings in tests
    :preamble => "require 'riak'\n\nRiak.disable_list_keys_warnings = true\n\n"
  },
  'simple_couch' => {
    :store => :Couch,
    :options => ":db => 'simple_couch'"
  },
  'simple_mongo' => {
    :store => :Mongo,
    :options => ":db => 'simple_mongo'"
  },
  'simple_null' => {
    :store => :Null,
    :specs => [:null, :marshallable_key, :returndifferent]
  },
  'null_adapter' => {
    :build => 'Juno::Adapters::Null.new',
    :specs => :null
  },
  'simple_sequel' => {
    :store => :Sequel,
    :options => ":db => (defined?(JRUBY_VERSION) ? 'jdbc:sqlite:/' : 'sqlite:/')"
  },
  'simple_datamapper' => {
    :store => :DataMapper,
    :options => ':setup => "sqlite3://#{make_tempdir}/simple_datamapper-default.sqlite3"',
    # DataMapper needs default repository to be setup
    :preamble => "require 'dm-core'\nDataMapper.setup(:default, :adapter => :in_memory)\n"
  },
  'simple_datamapper_with_repository' => {
    :store => :DataMapper,
    :options => ':repository => :repo, :setup => "sqlite3://#{make_tempdir}/simple_datamapper-repo.sqlite3"',
    # DataMapper needs default repository to be setup
    :preamble => "require 'dm-core'\nDataMapper.setup(:default, :adapter => :in_memory)\n"
  },
  'simple_activerecord' => {
    :store => :ActiveRecord,
    :options => ":connection => { :adapter => (defined?(JRUBY_VERSION) ? 'jdbcsqlite3' : 'sqlite3'), :database => File.join(make_tempdir, 'simple_activerecord.sqlite3') }"
  },
  'simple_fog' => {
    :store                  => :Fog,
    :options => ":aws_access_key_id => 'fake_access_key_id',
    :aws_secret_access_key  => 'fake_secret_access_key',
    :provider               => 'AWS',
    :dir                    => 'juno'",
    # Put Fog into testing mode
    :preamble               => "require 'fog'\nFog.mock!\n"
  },
  # 'cache' => {
  # },
  'expires_memory' => {
    :build => %{
Juno.build do
  use :Expires
  adapter :Memory
end},
    :specs => [:null, :store, :expires]
  },
  'expires_file' => {
    :build => %{
Juno.build do
  use :Expires
  use :Transformer, :key => [:marshal, :escape], :value => :marshal
  adapter :File, :dir => File.join(make_tempdir, "expires-file")
end},
    :specs => [:null, :store, :expires, :returndifferent, :marshallable_key],
    :tests => %{
it 'should delete expired value in underlying file storage' do
  @store.store('foo', 'bar', :expires => 2)
  @store['foo'].should == 'bar'
  sleep 1
  @store['foo'].should == 'bar'
  sleep 2
  @store['foo'].should == nil
  @store.adapter['foo'].should == nil
  @store.adapter.adapter['foo'].should == nil
end
}
  },
  'proxy_redis' => {
    :build => %{
Juno.build do
  use :Proxy
  use :Proxy
  adapter :Redis
end},
    :specs => ADAPTER_SPECS + [:expires_stringkey_stringvalue]
  },
  'proxy_expires_memory' => {
    :build => %{
Juno.build do
  use :Proxy
  use :Expires
  use :Proxy
  adapter :Memory
end},
    :specs => [:null, :store, :expires]
  },
  'cache_file_memory' => {
    :build => %{
Juno.build do
  use(:Cache) do
    backend { adapter :File, :dir => File.join(make_tempdir, "cache_file_memory") }
    cache { adapter :Memory }
  end
end},
    :specs => ADAPTER_SPECS,
    :tests => %{
it 'should store loaded values in cache' do
  @store.backend['foo'] = 'bar'
  @store.cache['foo'].should == nil
  @store['foo'].should == 'bar'
  @store.cache['foo'].should == 'bar'
  @store.backend.delete('foo')
  @store['foo'].should == 'bar'
  @store.delete('foo')
  @store['foo'].should == nil
end
}
  },
  'cache_memory_null' => {
    :build => %{
Juno.build do
  use(:Cache) do
    backend(Juno::Adapters::Memory.new)
    cache(Juno::Adapters::Null.new)
  end
end},
    :specs => ADAPTER_SPECS
  },
  'stack_file_memory' => {
    :build => %{
Juno.build do
  use(:Stack) do
    add(Juno.new(:Null))
    add(Juno::Adapters::Null.new)
    add { adapter :File, :dir => File.join(make_tempdir, "stack-file1") }
    add { adapter :Memory }
  end
end},
    :specs => ADAPTER_SPECS
  },
  'stack_memory_file' => {
    :build => %{
Juno.build do
  use(:Stack) do
    add(Juno.new(:Null))
    add(Juno::Adapters::Null.new)
    add { adapter :Memory }
    add { adapter :File, :dir => File.join(make_tempdir, "stack-file2") }
  end
end},
    :specs => [:null_stringkey_stringvalue, :store_stringkey_stringvalue]
  },
  'transformer_json' => {
    :build => %{
Juno.build do
  use :Transformer, :key => :json, :value => :json
  adapter :Memory
end},
    :key => %w(Hash String),
    :value => %w(Hash String),
    :specs => [:null, :store, :returndifferent]
  },
  'transformer_bson' => {
    :build => %{
Juno.build do
  use :Transformer, :key => :bson, :value => :bson
  adapter :Memory
end},
    :key => %w(Hash String),
    :value => %w(Hash String),
    :specs => [:null, :store, :returndifferent]
  },
#  'transformer_tnet' => {
#    :build => %{
#Juno.build do
#  use :Transformer, :key => :tnet, :value => :tnet
#  adapter :Memory
#end},
#    :key => %w(Hash String),
#    :value => %w(Hash String),
#    :specs => [:null, :store, :returndifferent]
#  },
  'transformer_msgpack' => {
    :build => %{
Juno.build do
  use :Transformer, :key => :msgpack, :value => :msgpack
  adapter :Memory
end},
    :key => %w(Hash String),
    :value => %w(Hash String),
    :specs => [:null, :store, :returndifferent]
  },
  'transformer_yaml' => {
    :build => %{
Juno.build do
  use :Transformer, :key => :yaml, :value => :yaml
  adapter :Memory
end},
    :specs => [:null, :store, :returndifferent]
  },
  'transformer_marshal_base64' => {
    :build => %{
Juno.build do
  use :Transformer, :key => [:marshal, :base64], :value => [:marshal, :base64]
  adapter :Memory
end},
    :specs => [:null, :store, :returndifferent, :marshallable_key]
  },
  'transformer_marshal_escape' => {
    :build => %{
Juno.build do
  use :Transformer, :key => [:marshal, :escape], :value => :marshal
  adapter :Memory
end},
    :specs => [:null, :store, :returndifferent, :marshallable_key]
  },
  'transformer_marshal_md5' => {
    :build => %{
Juno.build do
  use :Transformer, :key => [:marshal, :md5], :value => :marshal
  adapter :Memory
end},
    :specs => [:null, :store, :returndifferent, :marshallable_key]
  },
  'transformer_marshal_md5_spread' => {
    :build => %{
Juno.build do
  use :Transformer, :key => [:marshal, :md5, :spread], :value => :marshal
  adapter :Memory
end},
    :specs => [:null, :store, :returndifferent, :marshallable_key]
  },
  'adapter_activerecord' => {
    :build => "Juno::Adapters::ActiveRecord.new(:connection => { :adapter => (defined?(JRUBY_VERSION) ? 'jdbcsqlite3' : 'sqlite3'), :database => File.join(make_tempdir, 'adapter_activerecord.sqlite3') })",
    :specs => ADAPTER_SPECS,
    :tests => %{
it 'updates an existing key/value' do
  @store['foo/bar'] = '1'
  @store['foo/bar'] = '2'
  records = @store.table.find :all, :conditions => { :key => 'foo/bar' }
  records.count.should == 1
end

it 'uses an existing connection' do
  ActiveRecord::Base.establish_connection :adapter => (defined?(JRUBY_VERSION) ? 'jdbcsqlite3' : 'sqlite3'), :database => File.join(make_tempdir, 'activerecord-existing.sqlite3')

  store = Juno::Adapters::ActiveRecord.new
  store.table.table_exists?.should == true
end
}
  },
  'adapter_cassandra' => {
    :build => "Juno::Adapters::Cassandra.new",
    :specs => ADAPTER_SPECS
  },
  'adapter_couch' => {
    :build => "Juno::Adapters::Couch.new(:db => 'adapter_couch')",
    :specs => ADAPTER_SPECS
  },
  'adapter_datamapper' => {
    :build => 'Juno::Adapters::DataMapper.new(:setup => "sqlite3://#{make_tempdir}/adapter_datamapper.sqlite3")',
    # DataMapper needs default repository to be setup
    :preamble => "require 'dm-core'\nDataMapper.setup(:default, :adapter => :in_memory)\n",
    :specs => ADAPTER_SPECS + [:returndifferent_stringkey_objectvalue,
                               :null_stringkey_objectvalue,
                               :store_stringkey_objectvalue],
    :tests => %q{
it 'does not cross contaminate when storing' do
  first = Juno::Adapters::DataMapper.new(:setup => "sqlite3://#{make_tempdir}/datamapper-first.sqlite3")
  first.clear

  second = Juno::Adapters::DataMapper.new(:repository => :sample, :setup => "sqlite3://#{make_tempdir}/datamapper-second.sqlite3")
  second.clear

  first['key'] = 'value'
  second['key'] = 'value2'

  first['key'].should == 'value'
  second['key'].should == 'value2'
end

it 'does not cross contaminate when deleting' do
  first = Juno::Adapters::DataMapper.new(:setup => "sqlite3://#{make_tempdir}/datamapper-first.sqlite3")
  first.clear

  second = Juno::Adapters::DataMapper.new(:repository => :sample, :setup => "sqlite3://#{make_tempdir}/datamapper-second.sqlite3")
  second.clear

  first['key'] = 'value'
  second['key'] = 'value2'

  first.delete('key').should == 'value'
  first.key?('key').should == false
  second['key'].should == 'value2'
end
}
  },
  'adapter_dbm' => {
    :build => 'Juno::Adapters::DBM.new(:file => File.join(make_tempdir, "adapter_dbm"))',
    :specs => ADAPTER_SPECS
  },
  'adapter_file' => {
    :build => 'Juno::Adapters::File.new(:dir => File.join(make_tempdir, "adapter_file"))',
    :specs => ADAPTER_SPECS
  },
  'adapter_fog' => {
    :build => "Juno::Adapters::Fog.new(:aws_access_key_id => 'fake_access_key_id',
    :aws_secret_access_key  => 'fake_secret_access_key',
    :provider               => 'AWS',
    :dir                    => 'juno')",
    # Put Fog into testing mode
    :preamble               => "require 'fog'\nFog.mock!\n",
    :specs => ADAPTER_SPECS
  },
  'adapter_gdbm' => {
    :build => 'Juno::Adapters::GDBM.new(:file => File.join(make_tempdir, "adapter_gdbm"))',
    :specs => ADAPTER_SPECS
  },
  'adapter_localmemcache' => {
    :build => 'Juno::Adapters::LocalMemCache.new(:file => File.join(make_tempdir, "adapter_localmemcache"))',
    :specs => ADAPTER_SPECS
  },
  'adapter_memcached_dalli' => {
    :build => 'Juno::Adapters::MemcachedDalli.new(:server => "localhost:22122", :namespace => "adapter_memcached_dalli")',
    :specs => ADAPTER_SPECS + [:expires_stringkey_stringvalue]
  },
  'adapter_memcached_native' => {
    :build => 'Juno::Adapters::MemcachedNative.new(:server => "localhost:22122", :namespace => "adapter_memcached_native")',
    :specs => ADAPTER_SPECS + [:expires_stringkey_stringvalue]
  },
  'adapter_memcached' => {
    :build => 'Juno::Adapters::Memcached.new(:server => "localhost:22122", :namespace => "adapter_memcached")',
    :specs => ADAPTER_SPECS + [:expires_stringkey_stringvalue]
  },
  'adapter_memory' => {
    :build => 'Juno::Adapters::Memory.new',
    :specs => [:null, :store]
  },
  'adapter_mongo' => {
    :build => 'Juno::Adapters::Mongo.new(:db => "adapter_mongo")',
    :specs => ADAPTER_SPECS
  },
  'adapter_pstore' => {
    :build => 'Juno::Adapters::PStore.new(:file => File.join(make_tempdir, "adapter_pstore"))',
    :specs => ADAPTER_SPECS + [:null_stringkey_objectvalue,
                               :store_stringkey_objectvalue,
                               :returndifferent_stringkey_objectvalue]
  },
  'adapter_redis' => {
    :build => 'Juno::Adapters::Redis.new',
    :specs => ADAPTER_SPECS + [:expires_stringkey_stringvalue]
  },
  'adapter_riak' => {
    :build => 'Juno::Adapters::Riak.new',
    :options => ":bucket => 'adapter_riak'",
    :specs => ADAPTER_SPECS,
    # We don't want Riak warnings in tests
    :preamble => "require 'riak'\n\nRiak.disable_list_keys_warnings = true\n\n"
  },
  'adapter_sdbm' => {
    :build => 'Juno::Adapters::SDBM.new(:file => File.join(make_tempdir, "adapter_sdbm"))',
    :specs => ADAPTER_SPECS
  },
  'adapter_sequel' => {
    :build => "Juno::Adapters::Sequel.new(:db => (defined?(JRUBY_VERSION) ? 'jdbc:sqlite:/' : 'sqlite:/'))",
    :specs => ADAPTER_SPECS
  },
  'adapter_sqlite' => {
    :build => 'Juno::Adapters::Sqlite.new(:file => ":memory:")',
    :specs => ADAPTER_SPECS
  },
  'adapter_tokyocabinet' => {
    :build => 'Juno::Adapters::TokyoCabinet.new(:file => File.join(make_tempdir, "adapter_tokyocabinet"))',
    :specs => ADAPTER_SPECS
  },
  'adapter_yaml' => {
    :build => 'Juno::Adapters::YAML.new(:file => File.join(make_tempdir, "adapter_yaml"))',
    :specs => ADAPTER_SPECS + [:null_stringkey_objectvalue,
                               :store_stringkey_objectvalue,
                               :returndifferent_stringkey_objectvalue]
  },
}

SPECS = {}

KEYS = {
  'String' => ['strkey1', 'strkey2'].map(&:inspect),
  'Object' => ['Value.new(:objkey1)', 'Value.new(:objkey2)'],
  'Hash' => [{'hashkey1' => 'hashkey2'}, {'hashkey3' => 'hashkey4'}].map(&:inspect)
}

VALUES = {
  'String' => ['strval1', 'strval2'].map(&:inspect),
  'Object' => ['Value.new(:objval1)', 'Value.new(:objval2)'],
  'Hash' => [{'hashval1' => 'hashval2'}, {'hashval3' => 'hashval4'}].map(&:inspect)
}

KEYS.each do |key_type, (key1,key2)|
  VALUES.each do |val_type, (val1,val2)|

    code = %{it "reads from keys that are #{key_type}s like a Hash" do
  @store[#{key1}].should == nil
  @store.load(#{key1}).should == nil
end

it "guarantees that the same #{val_type} value is returned when setting a #{key_type} key" do
  value = #{val1}
  (@store[#{key1}] = value).should equal(value)
end

it "returns false from key? if a #{key_type} key is not available" do
  @store.key?(#{key1}).should == false
end

it "returns nil from delete if an element for a #{key_type} key does not exist" do
  @store.delete(#{key1}).should == nil
end

it "removes all #{key_type} keys from the store with clear" do
  @store[#{key1}] = #{val1}
  @store[#{key2}] = #{val2}
  @store.clear.should equal(@store)
  @store.key?(#{key1}).should_not ==  true
  @store.key?(#{key2}).should_not == true
end

it "fetches a #{key_type} key with a default value with fetch, if the key is not available" do
  @store.fetch(#{key1}, #{val1}).should == #{val1}
end

it "fetches a #{key_type} key with a block with fetch, if the key is not available" do
  key = #{key1}
  value = #{val1}
  @store.fetch(key) do |k|
    k.should equal(key)
    value
  end.should equal(value)
end

it 'should accept options' do
  @store.key?(#{key1}, :option1 => 1).should == false
  @store.load(#{key1}, :option2 => 2).should == nil
  @store.fetch(#{key1}, nil, :option3 => 3).should == nil
  @store.delete(#{key1}, :option4 => 4).should == nil
  @store.clear(:option5 => 5).should equal(@store)
  @store.store(#{key1}, #{val1}, :option6 => 6).should == #{val1}
end}
    SPECS["null_#{key_type.downcase}key_#{val_type.downcase}value"] = code

    code = %{it "writes #{val_type} values to keys that are #{key_type}s like a Hash" do
  @store[#{key1}] = #{val1}
  @store[#{key1}].should == #{val1}
  @store.load(#{key1}).should == #{val1}
end

it "returns true from key? if a #{key_type} key is available" do
  @store[#{key1}] = #{val1}
  @store.key?(#{key1}).should == true
end

it "stores #{val_type} values with #{key_type} keys with #store" do
  value = #{val1}
  @store.store(#{key1}, value).should equal(value)
  @store[#{key1}].should == #{val1}
  @store.load(#{key1}).should == #{val1}
end

it "removes and returns a #{val_type} element with a #{key_type} key from the backing store via delete if it exists" do
  @store[#{key1}] = #{val1}
  @store.delete(#{key1}).should == #{val1}
  @store.key?(#{key1}).should == false
end

it "does not run the block if the #{key_type} key is available" do
  @store[#{key1}] = #{val1}
  unaltered = "unaltered"
  @store.fetch(#{key1}) { unaltered = "altered" }
  unaltered.should == "unaltered"
end

it "fetches a #{key_type} key with a default value with fetch, if the key is available" do
  @store[#{key1}] = #{val1}
  @store.fetch(#{key1}, #{val2}).should == #{val1}
end}
    SPECS["store_#{key_type.downcase}key_#{val_type.downcase}value"] = code

    code = %{it "guarantees that a different #{val_type} value is retrieved from the #{key_type} key" do
  value = #{val1}
  @store[#{key1}] = #{val1}
  @store[#{key1}].should_not be_equal(#{val1})
end}
    SPECS["returndifferent_#{key_type.downcase}key_#{val_type.downcase}value"] = code

    code = %{it 'should support expires on store and #[]' do
  @store.store(#{key1}, #{val1}, :expires => 2)
  @store[#{key1}].should == #{val1}
  sleep 1
  @store[#{key1}].should == #{val1}
  sleep 2
  @store[#{key1}].should == nil
end

it 'should support expires on store and load' do
  @store.store(#{key1}, #{val1}, :expires => 2)
  @store.load(#{key1}).should == #{val1}
  sleep 1
  @store.load(#{key1}).should == #{val1}
  sleep 2
  @store.load(#{key1}).should == nil
end

it 'should support expires on store and key?' do
  @store.store(#{key1}, #{val1}, :expires => 2)
  @store.key?(#{key1}).should == true
  sleep 1
  @store.key?(#{key1}).should == true
  sleep 2
  @store.key?(#{key1}).should == false
end

it 'should support updating the expiration time in load' do
  @store.store(#{key2}, #{val2}, :expires => 2)
  @store[#{key2}].should == #{val2}
  sleep 1
  @store.load(#{key2}, :expires => 3).should == #{val2}
  @store[#{key2}].should == #{val2}
  sleep 1
  @store[#{key2}].should == #{val2}
  sleep 3
  @store[#{key2}].should == nil
end

it 'should support updating the expiration time in fetch' do
  @store.store(#{key1}, #{val1}, :expires => 2)
  @store[#{key1}].should == #{val1}
  sleep 1
  @store.fetch(#{key1}, nil, :expires => 3).should == #{val1}
  @store[#{key1}].should == #{val1}
  sleep 1
  @store[#{key1}].should == #{val1}
  sleep 3
  @store[#{key1}].should == nil
end

it 'should respect expires in delete' do
  @store.store(#{key2}, #{val2}, :expires => 2)
  @store[#{key2}].should == #{val2}
  sleep 1
  @store[#{key2}].should == #{val2}
  sleep 2
  @store.delete(#{key2}).should == nil
end}
    SPECS["expires_#{key_type.downcase}key_#{val_type.downcase}value"] = code

  end
end

SPECS["marshallable_key"]  = %{it "refuses to #[] from keys that cannot be marshalled" do
  expect do
    @store[Struct.new(:foo).new(:bar)]
  end.to raise_error(marshal_error)
end

it "refuses to load from keys that cannot be marshalled" do
  expect do
    @store.load(Struct.new(:foo).new(:bar))
  end.to raise_error(marshal_error)
end

it "refuses to fetch from keys that cannot be marshalled" do
  expect do
    @store.fetch(Struct.new(:foo).new(:bar), true)
  end.to raise_error(marshal_error)
end

it "refuses to #[]= to keys that cannot be marshalled" do
  expect do
    @store[Struct.new(:foo).new(:bar)] = 'value'
  end.to raise_error(marshal_error)
end

it "refuses to store to keys that cannot be marshalled" do
  expect do
    @store.store Struct.new(:foo).new(:bar), 'value'
  end.to raise_error(marshal_error)
end

it "refuses to check for key? if the key cannot be marshalled" do
  expect do
    @store.key? Struct.new(:foo).new(:bar)
  end.to raise_error(marshal_error)
end

it "refuses to delete a key if the key cannot be marshalled" do
  expect do
    @store.delete Struct.new(:foo).new(:bar)
  end.to raise_error(marshal_error)
end}

specs_code = ''
SPECS.each do |key, code|
  specs_code << "#################### #{key} ####################\n\n" <<
    "shared_examples_for '#{key}' do\n  " << code.gsub("\n", "\n  ") << "\nend\n\n"
end
specs_code.gsub!(/\n +\n/, "\n\n")
File.open(File.join(File.dirname(__FILE__), "junospecs.rb"), 'w') {|out| out << specs_code }

TESTS.each do |name, options|
  build = options.delete(:build)
  store = options.delete(:store)
  key = [options.delete(:key) || %w(Object String Hash)].flatten
  value = [options.delete(:value) || %w(Object String Hash)].flatten

  specs = [options.delete(:specs) || SIMPLE_SPECS].flatten
  specs_code = ''
  specs.each do |s|
    specs_code << "    it_should_behave_like '#{s}'\n" if SPECS[s.to_s]
    key.each do |k|
      value.each do |v|
        x = "#{s}_#{k.downcase}key_#{v.downcase}value"
        specs_code << "    it_should_behave_like '#{x}'\n" if SPECS[x]
      end
    end
  end

  preamble = options.delete(:preamble).to_s.gsub("\n", "\n  ")
  opts = options.delete(:options)
  opts = ', ' << opts if opts

  build ||= "Juno.new(#{store.inspect}#{opts})"

  code = %{# Generated file
require 'helper'

begin
  #{preamble}#{build}.close

  describe #{name.inspect} do
    before do
      @store = #{build}
      @store.clear
    end

    after do
      @store.close.should == nil if @store
    end

#{specs_code}#{options[:tests].to_s.gsub("\n", "\n    ")}
  end
rescue LoadError => ex
  puts "Test #{name} not executed: \#{ex.message}"
rescue Exception => ex
  puts "Test #{name} not executed: \#{ex.message}"
  #puts "\#{ex.backtrace.join("\\n")}"
end
}

  code.gsub!(/\n +\n/, "\n\n")
  File.open(File.join(File.dirname(__FILE__), "#{name}_spec.rb"), 'w') {|out| out << code }
end
