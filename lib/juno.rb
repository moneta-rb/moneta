module Juno
  autoload :Base,              'juno/base'
  autoload :Builder,           'juno/builder'
  autoload :Cache,             'juno/cache'
  autoload :Expires,           'juno/expires'
  autoload :Proxy,             'juno/proxy'
  autoload :Stack,             'juno/stack'
  autoload :Transformer,       'juno/transformer'

  module Adapters
    autoload :ActiveRecord,    'juno/adapters/activerecord'
    autoload :Cassandra,       'juno/adapters/cassandra'
    autoload :Couch,           'juno/adapters/couch'
    autoload :DataMapper,      'juno/adapters/datamapper'
    autoload :DBM,             'juno/adapters/dbm'
    autoload :File,            'juno/adapters/file'
    autoload :Fog,             'juno/adapters/fog'
    autoload :GDBM,            'juno/adapters/gdbm'
    autoload :LocalMemCache,   'juno/adapters/localmemcache'
    autoload :Memcached,       'juno/adapters/memcached'
    autoload :MemcachedDalli,  'juno/adapters/memcached_dalli'
    autoload :MemcachedNative, 'juno/adapters/memcached_native'
    autoload :Memory,          'juno/adapters/memory'
    autoload :Mongo,           'juno/adapters/mongo'
    autoload :Null,            'juno/adapters/null'
    autoload :PStore,          'juno/adapters/pstore'
    autoload :Redis,           'juno/adapters/redis'
    autoload :Riak,            'juno/adapters/riak'
    autoload :SDBM,            'juno/adapters/sdbm'
    autoload :Sequel,          'juno/adapters/sequel'
    autoload :Sqlite,          'juno/adapters/sqlite'
    autoload :TokyoCabinet,    'juno/adapters/tokyocabinet'
    autoload :YAML,            'juno/adapters/yaml'
  end

  def self.new(name, options = {})
    raise 'Name must be Symbol' unless Symbol === name
    case name
    when :Sequel, :ActiveRecord, :Couch
      # Sequel accept only base64 keys and values
      # FIXME: ActiveRecord and Couch should work only with :marshal but this
      # raises an error on 1.9
      build(options) do
        use :Transformer, :key => [:marshal, :base64], :value => [:marshal, :base64]
        adapter name
      end
    when :Memcached, :MemcachedDalli, :MemcachedNative
      # Memcached accept only base64 keys
      build(options) do
        use :Transformer, :key => [:marshal, :base64], :value => :marshal
        adapter name
      end
    when :PStore, :YAML, :DataMapper, :Null
      # For PStore, YAML and DataMapper only the key has to be a string
      build(options) do
        use :Transformer, :key => :marshal
        adapter name
      end
    when :HashFile
      # Use spreading hashes
      build(options) do
        use :Transformer, :key => [:marshal, :md5, :spread], :value => :marshal
        adapter :File
      end
    when :File
      # Use escaping
      build(options) do
        use :Transformer, :key => [:marshal, :escape], :value => :marshal
        adapter :File
      end
    else
      # For all other stores marshal key and value
      build(options) do
        use :Transformer, :key => :marshal, :value => :marshal
        adapter name
      end
    end
  end

  def self.build(options = {}, &block)
    Builder.new(options, &block).build
  end
end
