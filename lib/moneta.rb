# Provides two methods for constructing stores:
#
# * {Moneta.new}
# * {Moneta.build}
module Moneta
  autoload :Builder,           'moneta/builder'
  autoload :Cache,             'moneta/cache'
  autoload :CreateSupport,     'moneta/mixins'
  autoload :Defaults,          'moneta/mixins'
  autoload :EachKeySupport,    'moneta/mixins'
  autoload :Enumerable,        'moneta/enumerable'
  autoload :ExpiresSupport,    'moneta/mixins'
  autoload :Expires,           'moneta/expires'
  autoload :Fallback,          'moneta/fallback'
  autoload :HashAdapter,       'moneta/mixins'
  autoload :IncrementSupport,  'moneta/mixins'
  autoload :Lock,              'moneta/lock'
  autoload :Logger,            'moneta/logger'
  autoload :Mutex,             'moneta/synchronize'
  autoload :OptionMerger,      'moneta/optionmerger'
  autoload :OptionSupport,     'moneta/mixins'
  autoload :Pool,              'moneta/pool'
  autoload :Proxy,             'moneta/proxy'
  autoload :Semaphore,         'moneta/synchronize'
  autoload :Server,            'moneta/server'
  autoload :Shared,            'moneta/shared'
  autoload :Stack,             'moneta/stack'
  autoload :Transformer,       'moneta/transformer'
  autoload :Utils,             'moneta/utils'
  autoload :WeakCreate,        'moneta/weak'
  autoload :WeakEachKey,       'moneta/weak_each_key'
  autoload :WeakIncrement,     'moneta/weak'
  autoload :Wrapper,           'moneta/wrapper'

  # Adapters are classes which wrap databases, services etc., as described in
  # {file:SPEC.md The Moneta Specification}.
  module Adapters
    autoload :ActiveRecord,    'moneta/adapters/activerecord'
    autoload :ActiveSupportCache, 'moneta/adapters/activesupportcache'
    autoload :Cassandra,       'moneta/adapters/cassandra'
    autoload :Client,          'moneta/adapters/client'
    autoload :Cookie,          'moneta/adapters/cookie'
    autoload :Couch,           'moneta/adapters/couch'
    autoload :Daybreak,        'moneta/adapters/daybreak'
    autoload :DBM,             'moneta/adapters/dbm'
    autoload :DataMapper,      'moneta/adapters/datamapper'
    autoload :File,            'moneta/adapters/file'
    autoload :Fog,             'moneta/adapters/fog'
    autoload :GDBM,            'moneta/adapters/gdbm'
    autoload :HBase,           'moneta/adapters/hbase'
    autoload :LRUHash,         'moneta/adapters/lruhash'
    autoload :KyotoCabinet,    'moneta/adapters/kyotocabinet'
    autoload :LevelDB,         'moneta/adapters/leveldb'
    autoload :LMDB,            'moneta/adapters/lmdb'
    autoload :LocalMemCache,   'moneta/adapters/localmemcache'
    autoload :Memcached,       'moneta/adapters/memcached'
    autoload :MemcachedDalli,  'moneta/adapters/memcached/dalli'
    autoload :MemcachedNative, 'moneta/adapters/memcached/native'
    autoload :Memory,          'moneta/adapters/memory'
    autoload :Mongo,           'moneta/adapters/mongo'
    autoload :MongoMoped,      'moneta/adapters/mongo/moped'
    autoload :MongoOfficial,   'moneta/adapters/mongo/official'
    autoload :Null,            'moneta/adapters/null'
    autoload :PStore,          'moneta/adapters/pstore'
    autoload :Redis,           'moneta/adapters/redis'
    autoload :RestClient,      'moneta/adapters/restclient'
    autoload :Riak,            'moneta/adapters/riak'
    autoload :SDBM,            'moneta/adapters/sdbm'
    autoload :Sequel,          'moneta/adapters/sequel'
    autoload :Sqlite,          'moneta/adapters/sqlite'
    autoload :TDB,             'moneta/adapters/tdb'
    autoload :TokyoCabinet,    'moneta/adapters/tokyocabinet'
    autoload :TokyoTyrant,     'moneta/adapters/tokyotyrant'
    autoload :YAML,            'moneta/adapters/yaml'
  end

  # Create new Moneta store with default proxies
  #
  # This works in most cases if you don't want fine
  # control over the proxy stack. It uses Marshal on the
  # keys and values. Use Moneta#build if you want to have fine control!
  #
  # @param [Symbol] name Name of adapter (See Moneta::Adapters)
  # @param [Hash] options
  # @return [Moneta store] newly created Moneta store
  # @option options [Boolean/Integer] :expires Ensure that store supports expiration by inserting
  #                                            {Expires} if the underlying adapter doesn't support it natively
  #                                            and set default expiration time
  # @option options [Boolean] :threadsafe (false) Ensure that the store is thread safe by inserting Moneta::Lock
  # @option options [Boolean/Hash] :logger (false) Add logger to proxy stack (Hash is passed to logger as options)
  # @option options [Boolean/Symbol] :compress (false) If true, compress value with zlib, or specify custom compress, e.g. :quicklz
  # @option options [Symbol] :serializer (:marshal) Serializer used for key and value, disable with nil
  # @option options [Symbol] :key_serializer (options[:serializer]) Serializer used for key, disable with nil
  # @option options [Symbol] :value_serializer (options[:serializer]) Serializer used for value, disable with nil
  # @option options [String] :prefix Key prefix used for namespacing (default none)
  # @option options All other options passed to the adapter
  #
  # Supported adapters:
  # * :HashFile (Store which spreads the entries using a md5 hash, e.g. cache/42/391dd7535aebef91b823286ac67fcd)
  # * :File (normal file store)
  # * :Memcached (Memcached store)
  # * ... (All other adapters from Moneta::Adapters)
  #
  # @api public
  def self.new(name, options = {})
    expires = options[:expires]
    options.delete(:expires) unless Numeric === expires
    logger = options.delete(:logger)
    threadsafe = options.delete(:threadsafe)
    compress = options.delete(:compress)
    serializer = options.include?(:serializer) ? options.delete(:serializer) : :marshal
    key_serializer = options.include?(:key_serializer) ? options.delete(:key_serializer) : serializer
    value_serializer = options.include?(:value_serializer) ? options.delete(:value_serializer) : serializer
    transformer = { key: [key_serializer, :prefix], value: [value_serializer], prefix: options.delete(:prefix) }
    transformer[:value] << (Symbol === compress ? compress : :zlib) if compress
    raise ArgumentError, 'Name must be Symbol' unless Symbol === name
    case name
    when :Sequel
      # Sequel accept only base64 keys
      transformer[:key] << :base64
      # If using HStore, binary data is not allowed
      transformer[:value] << :base64 if options[:hstore]
    when :ActiveRecord, :DataMapper
      # DataMapper and AR accept only base64 keys and values
      transformer[:key] << :base64
      transformer[:value] << :base64
    when :Couch
      # CouchDB needs to use URL-safe Base64 for its keys
      transformer[:key] << :urlsafe_base64
      transformer[:value] << :base64
    when :PStore, :YAML, :Null
      # For PStore and YAML only the key has to be a string
      transformer.delete(:value) if transformer[:value] == [:marshal]
    when :HashFile
      # Use spreading hashes
      transformer[:key] << :md5 << :spread
      name = :File
    when :File, :Riak, :RestClient
      # Use escaping for file and HTTP interfaces
      transformer[:key] << :escape
    end
    a = Adapters.const_get(name).new(options)
    build do
      use :Logger, Hash === logger ? logger : {} if logger
      use :Expires, expires: options[:expires] if !a.supports?(:expires) && expires
      use :Transformer, transformer
      use :Lock if threadsafe
      adapter a
    end
  end

  # Configure your own Moneta proxy stack
  #
  # @yieldparam Builder block
  # @return [Moneta store] newly created Moneta store
  #
  # @example Moneta builder
  #   Moneta.build do
  #     use :Expires
  #     adapter :Memory
  #   end
  #
  # @api public
  def self.build(&block)
    Builder.new(&block).build.last
  end
end
