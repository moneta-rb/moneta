module Juno
  autoload :Base,              'juno/base'
  autoload :Builder,           'juno/builder'
  autoload :Cache,             'juno/cache'
  autoload :Expires,           'juno/expires'
  autoload :Lock,              'juno/lock'
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
    autoload :LRUHash,         'juno/adapters/lruhash'
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
    expires = options.delete(:expires)
    threadsafe = options.delete(:threadsafe)
    transformer = {:key => :marshal, :value => :marshal}
    raise 'Name must be Symbol' unless Symbol === name
    case name
    when :Sequel, :ActiveRecord, :Couch
      # Sequel accept only base64 keys and values
      # FIXME: ActiveRecord and Couch should work only with :marshal but this
      # raises an error on 1.9
      transformer = {:key => [:marshal, :base64], :value => [:marshal, :base64]}
    when :Memcached, :MemcachedDalli, :MemcachedNative
      # Memcached accept only base64 keys, expires already supported
      expires = false
      transformer = {:key => [:marshal, :base64], :value => :marshal}
    when :PStore, :YAML, :DataMapper, :Null
      # For PStore, YAML and DataMapper only the key has to be a string
      transformer = {:key => :marshal}
    when :HashFile
      # Use spreading hashes
      transformer = {:key => [:marshal, :md5, :spread], :value => :marshal}
      name = :File
    when :File
      # Use escaping
      transformer = {:key => [:marshal, :escape], :value => :marshal}
    when :Cassandra, :Redis
      # Expires already supported
      expires = false
    end
    build(options) do
      use :Expires if expires
      use :Transformer, transformer
      use :Lock if threadsafe
      adapter name
    end
  end

  def self.build(options = {}, &block)
    Builder.new(options, &block).build
  end
end
