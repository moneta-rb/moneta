module Juno
  autoload :Base,              'juno/base'
  autoload :Builder,           'juno/builder'
  autoload :Cache,             'juno/cache'
  autoload :Expires,           'juno/expires'
  autoload :Lock,              'juno/lock'
  autoload :Logger,            'juno/logger'
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

  # Create new Juno store with default proxies
  # which works in most cases if you don't want fine
  # control over the proxy chain. It uses Marshal on the
  # keys and values. Use Juno#build if you want to have fine control!
  #
  # @param [Symbol] name Name of adapter (See Juno::Adapters)
  # @param [Hash] options
  #
  # Options:
  # * :expires - If true, ensure that store supports expiration by inserting
  #   Juno::Expires if the underlying adapter doesn't support it natively
  # * :threadsafe - If true, ensure that the store is thread safe by inserting Juno::Lock
  # * :logger - If true or Hash, add logger to chain (Hash is passed to logger as options)
  # * :compress - If true, compress value with zlib, or specify custom compress, e.g. :quicklz
  # * :serializer - Serializer used for key and value (default :marshal, disable with nil)
  # * :key_serializer - Serializer used for key (default options[:serializer])
  # * :value_serializer - Serializer used for key (default options[:serializer])
  # * :prefix - Key prefix used for namespacing (default none)
  # * All other options passed to the adapter
  #
  # Supported adapters:
  # * :HashFile (Store which spreads the entries using a md5 hash, e.g. cache/42/391dd7535aebef91b823286ac67fcd)
  # * :File (normal file store)
  # * :Memcached (Memcached store)
  # * ... (All other adapters from Juno::Adapters)
  def self.new(name, options = {})
    expires = options.delete(:expires)
    logger = options.delete(:logger)
    threadsafe = options.delete(:threadsafe)
    compress = options.delete(:compress)
    serializer = options.delete(:serializer) || :marshal
    key_serializer = options.delete(:key_serializer) || serializer
    value_serializer = options.delete(:value_serializer) || serializer
    transformer = { :key => [key_serializer], :value => [value_serializer], :prefix => options.delete(:prefix) }
    transformer[:key] << :prefix if transformer[:prefix]
    transformer[:value] << (Symbol === compress ? compress : :zlib) if compress
    raise 'Name must be Symbol' unless Symbol === name
    case name
    when :Sequel, :ActiveRecord, :Couch
      # Sequel accept only base64 keys and values
      # FIXME: Couch should work only with :marshal but this raises an error on 1.9
      transformer[:key] << :base64
      transformer[:value] << :base64
    when :Memcached, :MemcachedDalli, :MemcachedNative
      # Memcached accept only base64 keys, expires already supported
      expires = false
      transformer[:key] << :base64
    when :PStore, :YAML, :DataMapper, :Null
      # For PStore, YAML and DataMapper only the key has to be a string
      transformer.delete(:value) if transformer[:value] == [:marshal]
    when :HashFile
      # Use spreading hashes
      transformer[:key] << :md5 << :spread
      name = :File
    when :File
      # Use escaping
      transformer[:key] << :escape
    when :Cassandra, :Redis
      # Expires already supported
      expires = false
    end
    build do
      use :Logger, Hash === logger ? logger : {} if logger
      use :Expires if expires
      use :Transformer, transformer
      use :Lock if threadsafe
      adapter name, options
    end
  end

  # Build your own store chain!
  #
  # Example:
  #
  #     Juno.build do
  #       use :Expires
  #       adapter :Memory
  #     end
  def self.build(&block)
    Builder.new(&block).build
  end
end
