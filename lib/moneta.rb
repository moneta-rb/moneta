module Moneta
  autoload :Base,              'moneta/base'
  autoload :Builder,           'moneta/builder'
  autoload :Cache,             'moneta/cache'
  autoload :Expires,           'moneta/expires'
  autoload :Lock,              'moneta/lock'
  autoload :Logger,            'moneta/logger'
  autoload :Mixins,            'moneta/mixins'
  autoload :Net,               'moneta/net'
  autoload :OptionMerger,      'moneta/optionmerger'
  autoload :Proxy,             'moneta/proxy'
  autoload :Server,            'moneta/server'
  autoload :Shared,            'moneta/shared'
  autoload :Stack,             'moneta/stack'
  autoload :Transformer,       'moneta/transformer'
  autoload :Wrapper,           'moneta/wrapper'

  module Adapters
    autoload :ActiveRecord,    'moneta/adapters/activerecord'
    autoload :Cassandra,       'moneta/adapters/cassandra'
    autoload :Client,          'moneta/adapters/client'
    autoload :Cookie,          'moneta/adapters/cookie'
    autoload :Couch,           'moneta/adapters/couch'
    autoload :DataMapper,      'moneta/adapters/datamapper'
    autoload :DBM,             'moneta/adapters/dbm'
    autoload :File,            'moneta/adapters/file'
    autoload :Fog,             'moneta/adapters/fog'
    autoload :GDBM,            'moneta/adapters/gdbm'
    autoload :HBase,           'moneta/adapters/hbase'
    autoload :LevelDB,         'moneta/adapters/leveldb'
    autoload :LocalMemCache,   'moneta/adapters/localmemcache'
    autoload :LRUHash,         'moneta/adapters/lruhash'
    autoload :Memcached,       'moneta/adapters/memcached'
    autoload :MemcachedDalli,  'moneta/adapters/memcached_dalli'
    autoload :MemcachedNative, 'moneta/adapters/memcached_native'
    autoload :Memory,          'moneta/adapters/memory'
    autoload :Mongo,           'moneta/adapters/mongo'
    autoload :Null,            'moneta/adapters/null'
    autoload :PStore,          'moneta/adapters/pstore'
    autoload :Redis,           'moneta/adapters/redis'
    autoload :Riak,            'moneta/adapters/riak'
    autoload :SDBM,            'moneta/adapters/sdbm'
    autoload :Sequel,          'moneta/adapters/sequel'
    autoload :Sqlite,          'moneta/adapters/sqlite'
    autoload :TokyoCabinet,    'moneta/adapters/tokyocabinet'
    autoload :YAML,            'moneta/adapters/yaml'
  end

  # Create new Moneta store with default proxies
  # which works in most cases if you don't want fine
  # control over the proxy chain. It uses Marshal on the
  # keys and values. Use Moneta#build if you want to have fine control!
  #
  # @param [Symbol] name Name of adapter (See Moneta::Adapters)
  # @param [Hash] options
  #
  # Options:
  # * :expires - If true or integer, ensure that store supports expiration by inserting
  #   Moneta::Expires if the underlying adapter doesn't support it natively
  # * :threadsafe - If true, ensure that the store is thread safe by inserting Moneta::Lock
  # * :logger - If true or Hash, add logger to chain (Hash is passed to logger as options)
  # * :compress - If true, compress value with zlib, or specify custom compress, e.g. :quicklz
  # * :serializer - Serializer used for key and value, disable with nil (default :marshal)
  # * :key_serializer - Serializer used for key, disable with nil (default options[:serializer] if not provided)
  # * :value_serializer - Serializer used for key, disable with nil (default options[:serializer] if not provided)
  # * :prefix - Key prefix used for namespacing (default none)
  # * All other options passed to the adapter
  #
  # Supported adapters:
  # * :HashFile (Store which spreads the entries using a md5 hash, e.g. cache/42/391dd7535aebef91b823286ac67fcd)
  # * :File (normal file store)
  # * :Memcached (Memcached store)
  # * ... (All other adapters from Moneta::Adapters)
  def self.new(name, options = {})
    expires = options.delete(:expires)
    logger = options.delete(:logger)
    threadsafe = options.delete(:threadsafe)
    compress = options.delete(:compress)
    serializer = options.include?(:serializer) ? options.delete(:serializer) : :marshal
    key_serializer = options.include?(:key_serializer) ? options.delete(:key_serializer) : serializer
    value_serializer = options.include?(:value_serializer) ? options.delete(:value_serializer) : serializer
    transformer = { :key => [key_serializer, :prefix], :value => [value_serializer], :prefix => options.delete(:prefix) }
    transformer[:value] << (Symbol === compress ? compress : :zlib) if compress
    raise ArgumentError, 'Name must be Symbol' unless Symbol === name
    case name
    when :Sequel, :ActiveRecord, :Couch, :DataMapper
      # Sequel accept only base64 keys and values
      # FIXME: Couch should work only with :marshal but this raises an error on 1.9
      transformer[:key] << :base64
      transformer[:value] << :base64
    when :Memcached, :MemcachedDalli, :MemcachedNative
      # Memcached accept only base64 keys, expires already supported
      options[:expires] = expires if Integer === expires
      expires = false
      transformer[:key] << :base64
    when :PStore, :YAML, :Null
      # For PStore and YAML only the key has to be a string
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
      options[:expires] = expires if Integer === expires
      expires = false
    end
    build do
      use :Logger, Hash === logger ? logger : {} if logger
      use :Expires, :expires => (Integer === expires ? expires : nil) if expires
      use :Transformer, transformer
      use :Lock if threadsafe
      adapter name, options
    end
  end

  # Build your own store chain!
  #
  # @example Moneta builder
  #   Moneta.build do
  #     use :Expires
  #     adapter :Memory
  #   end
  def self.build(&block)
    Builder.new(&block).build.last
  end
end
