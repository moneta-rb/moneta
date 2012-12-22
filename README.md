# Moneta: A unified interface for key/value stores

[![Build Status](https://secure.travis-ci.org/minad/moneta.png?branch=master)](http://travis-ci.org/minad/moneta) [![Dependency Status](https://gemnasium.com/minad/moneta.png?travis)](https://gemnasium.com/minad/moneta) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/minad/moneta)

Moneta provides a standard interface for interacting with various kinds of key/value stores. Moneta is very feature rich:

* Supports a lot of backends (See below)
* Supports proxies (Similar to [Rack middlewares](http://rack.github.com/))
* Custom serialization via `Moneta::Transformer` proxy (Marshal/JSON/YAML and many more)
* Custom key transformation via `Moneta::Transformer` proxy
* Value compression via `Moneta::Transformer` proxy (Zlib, Snappy, LZMA, ...)
* Expiration for all stores (Added via proxy `Moneta::Expires` if not supported natively)
* Atomic incrementation and decrementation for most stores (Method `#increment`)
* Includes a very simple key/value server (`Moneta::Server`) and client (`Moneta::Adapters::Client`)
* Integration with [Rails](http://rubyonrails.org/), [Rack](http://rack.github.com/) as cookie and session store and [Rack-Cache](https://github.com/rtomayko/rack-cache)

Moneta is tested thoroughly using [Travis-CI](http://travis-ci.org/minad/moneta).

## Links

* Source: <http://github.com/minad/moneta>
* Bugs:   <http://github.com/minad/moneta/issues>
* API documentation:
    * Latest Gem: <http://rubydoc.info/gems/moneta/frames>
    * GitHub master: <http://rubydoc.info/github/minad/moneta/master/frames>

## Supported backends

Out of the box, it supports the following backends:

* Memory:
    * In-memory store (`:Memory`)
    * LRU hash - prefer this over :Memory! (`:LRUHash`)
    * LocalMemCache (`:LocalMemCache`)
    * Memcached store (`:Memcached`, `:MemcachedNative` and `:MemcachedDalli`)
* Relational Databases:
    * DataMapper (`:DataMapper`)
    * ActiveRecord (`:ActiveRecord`)
    * Sequel (`:Sequel`)
    * Sqlite3 (`:Sqlite`)
* Filesystem:
    * PStore (`:PStore`)
    * YAML store (`:YAML`)
    * Filesystem directory store (`:File`)
    * Filesystem directory store which spreads files in subdirectories using md5 hash (`:HashFile`)
* Key/value databases:
    * Berkeley DB (`:DBM`)
    * Cassandra (`:Cassandra`)
    * GDBM (`:GDBM`)
    * HBase (`:HBase`)
    * LevelDB (`:LevelDB`)
    * Redis (`:Redis`)
    * Riak (`:Riak`)
    * SDBM (`:SDBM`)
    * TokyoCabinet (`:TokyoCabinet`)
* Document databases:
    * CouchDB (`:Couch`)
    * MongoDB (`:Mongo`)
* Other
    * Moneta key/value server client (`:Client` works with `Moneta::Server`)
    * Fog cloud storage which supports Amazon S3, Rackspace, etc. (`:Fog`)
    * Storage which doesn't store anything (`:Null`)

Some of the backends are not exactly based on key/value stores, e.g. the relational ones. These
are useful if you already use the corresponding backend in your application. You get a key/value
store for free then without installing any additional services and you still have the possibility
to upgrade to a real key/value store.

## Proxies

In addition it supports proxies (Similar to [Rack middlewares](http://rack.github.com/)) which
add additional features to storage backends:

* `Moneta::Proxy` and `Moneta::Wrapper` proxy base classes
* `Moneta::Expires` to add expiration support to stores which don't support it natively. Add it in the builder using `use :Expires`.
* `Moneta::Stack` to stack multiple stores (Read returns result from first where the key is found, writes go to all stores). Add it in the builder using `use :Stack`.
* `Moneta::Transformer` transforms keys and values (Marshal, YAML, JSON, Base64, MD5, ...). Add it in the builder using `use :Transformer`.
* `Moneta::Cache` combine two stores, one as backend and one as cache (e.g. `Moneta::Adapters::File` + `Moneta::Adapters::Memory`). Add it in the builder using `use :Cache`.
* `Moneta::Lock` to make store thread safe. Add it in the builder using `use :Lock`.
* `Moneta::Logger` to log database accesses. Add it in the builder using `use :Logger`.
* `Moneta::Shared` to share a store between multiple processes. Add it in the builder using `use :Shared`.

## Supported serializers and compressors (`Moneta::Transformer`)

Supported serializers:

* BEncode (`:bencode`)
* BERT (`:bert`)
* BSON (`:bson`)
* JSON (`:json`)
* Marshal (`:marshal`)
* MessagePack (`:msgpack`)
* Ox (`:ox`)
* TNetStrings (`:tnet`)
* YAML (`:yaml`)

Supported value compressors:

* LZMA (`:lzma`)
* LZO (`:lzo`)
* Snappy (`:snappy`)
* QuickLZ (`:quicklz`)
* Zlib (`:zlib`)

Special transformers:

* Digests (MD5, Shas, ...)
* Add prefix to keys (`:prefix`)
* HMAC to verify values (`:hmac`, useful for `Rack::MonetaCookies`)

## Moneta API

~~~
#initialize(options)                      options differs per-store, and is used to set up the store.

#[](key)                                  retrieve a key. If the key is not available, return nil.

#load(key, options = {})                  retrieve a key. If the key is not available, return nil.

#fetch(key, options = {}, &block)         retrieve a key. If the key is not available, execute the
                                          block and return its return value.

#fetch(key, value, options = {})          retrieve a key. If the key is not available, return the value,

#[]=(key, value)                          set a value for a key. If the key is already used, clobber it.
                                          keys set using []= will never expire.

#store(key, value, options = {})          same as []=, but you can supply options.

#delete(key, options = {})                delete the key from the store and return the current value.

#key?(key, options = {})                  true if the key exists, false if it does not.

#increment(key, amount = 1, options = {}) increment numeric value. This is a atomic operation
                                          which is not supported by all stores. Returns current value.

#clear(options = {})                      clear all keys in this store.

#close                                    close database connection.
~~~

The Moneta API is purposely extremely similar to the Hash API. In order so support an
identical API across stores, it does not support iteration or partial matches.

### Creating a Store

There is a simple interface to create a store using `Moneta.new`:

~~~ ruby
store = Moneta.new(:Memcached, :server => 'localhost:11211')
~~~

If you want to have control over the proxies, you have to use `Moneta.build`:

~~~ ruby
store = Moneta.build do
  # Adds expires proxy
  use :Expires
  # Transform key using Marshal and Base64 and value using Marshal
  use :Transformer, :key => [:marshal, :base64], :value => :marshal
  # Memory backend
  adapter :Memory
end
~~~

### Expiration

The Cassandra, Memcached and Redis backends supports expires values directly:

~~~ ruby
cache = Moneta::Adapters::Memcached.new

# Or using the builder...
cache = Moneta.build do
  adapter :Memcached
end

# Expires in 60 seconds
cache.store(key, value, :expires => 60)

# Update expires time if value is found
cache.load(key, :expires => 30)
cache.key?(key, :expires => 30)
~~~

You can add the expires feature to other backends using the Expires proxy:

~~~ ruby
# Using the :expires option
cache = Moneta.new(:File, :dir => '...', :expires => true)

# or manually by using the proxy...
cache = Moneta::Expires.new(Moneta::Adapters::File.new(:dir => '...'))

# or using the builder...
cache = Moneta.build do
  use :Expires
  adapter :File, :dir => '...'
end
~~~

### Incrementation and raw access

The stores support the `#increment` which allows atomic increments of unsigned integer values. If you increment
a non existing value, it will be created. If you increment a non integer value an exception will be raised.

~~~ ruby
store.increment('counter') => 1 # counter created
store.increment('counter') => 2
store.increment('counter', -1) => 1
store.increment('counter', 13) => 14
store.increment('counter', 0) => 14
store['name'] = 'Moneta'
store.increment('name') => Exception
~~~

If you want to access the counter value you have to use raw access to the datastore. This is only important
if you have a `Moneta::Transformer` somewhere in your proxy chain which transforms the values e.g. with `Marshal`.

~~~ ruby
store.increment('counter') => 1 # counter created
store.load('counter', :raw => true) => '1'

store.store('counter', '10', :raw => true)
store.increment('counter') => 11
~~~

Fortunately there is a nicer way to do this using some syntactic sugar!

~~~ ruby
store.increment('counter') => 1 # counter created
store.raw['counter'] => '1'
store.raw.load('counter') => '1'

store.raw['counter'] = '10'
store.increment('counter') => 11
~~~

## Framework Integration

Inspired by [redis-store](https://github.com/jodosha/redis-store) there exist integration classes for [Rails](http://rubyonrails.org/), [Rack](http://rack.github.com/) and [Rack-Cache](https://github.com/rtomayko/rack-cache).

### Rack session store

Use Moneta as a [Rack](http://rack.github.com/) session store:

~~~ ruby
require 'rack/session/moneta'

# Use only the adapter name
use Rack::Session::Moneta, :store => :Redis

# Use Moneta.new
use Rack::Session::Moneta, :store => Moneta.new(:Memory, :expires => true)

# Use the Moneta builder
use Rack::Session::Moneta do
  use :Expires
  adapter :Memory
end
~~~

### Rack cache

Use Moneta as a [Rack-Cache](https://github.com/rtomayko/rack-cache) store:

~~~ ruby
require 'rack/cache/moneta'

use Rack::Cache,
      :metastore   => 'moneta://Memory?expires=true',
      :entitystore => 'moneta://Memory?expires=true'

# Or used named Moneta stores
Rack::Cache::Moneta['named_metastore'] = Moneta.build do
  use :Expires
  adapter :Memory
end
use Rack::Cache,
      :metastore => 'moneta://named_metastore',
      :entity_store => 'moneta://named_entitystore'
~~~

### Rack cookies

Use Moneta to store cookies in [Rack](http://rack.github.com/). It uses the `Moneta::Adapters::Cookie`. You might
wonder what the purpose of this store or Rack middleware is: It makes it possible
to use all the transformers on the cookies (e.g. `:prefix`, `:marshal` and `:hmac` for value verification).

~~~ ruby
require 'rack/moneta_cookies'

use Rack::MonetaCookies, :domain => 'example.com', :path => '/path'
run lambda do |env|
  req = Rack::Request.new(env)
  req.cookies #=> is now a Moneta store!
  env['rack.request.cookie_hash'] #=> is now a Moneta store!
  req.cookies['key'] #=> retrieves 'key'
  req.cookies['key'] = 'value' #=> sets 'key'
  req.cookies.delete('key') #=> removes 'key'
  [200, {}, []]
end
~~~

### Rails session store

Add the session store in your application configuration `config/environments/*.rb`.

~~~ ruby
require 'moneta'

# Only by adapter name
config.cache_store :moneta_store, :store => :Memory

# Use Moneta.new
config.cache_store :moneta_store, :store => Moneta.new(:Memory)

# Use the Moneta builder
config.cache_store :moneta_store, :store => Moneta.build do
  use :Expires
  adapter :Memory
end
~~~

### Rails cache store

Add the cache store in your application configuration `config/environments/*.rb`. Unfortunately the
Moneta cache store doesn't support matchers. If you need these features use a different server-specific implementation.

~~~ ruby
require 'moneta'

# Only by adapter name
config.cache_store :moneta_store, :store => :Memory

# Use Moneta.new
config.cache_store :moneta_store, :store => Moneta.new(:Memory)

# Use the Moneta builder
config.cache_store :moneta_store, :store => Moneta.build do
  use :Expires
  adapter :Memory
end
~~~

## Advanced - Build your own key value server

You can use Moneta to build your own key/value server which is shared between
multiple processes. If you run the following code in two different processes,
they will share the same data which will also be persistet in the database `shared.db`.

~~~ ruby
require 'moneta'

store = Moneta.build do
  use :Transformer, :key => :marshal, :value => :marshal
  use :Shared do
    use :Cache do
      cache do
        adapter :LRUHash
      end
      backend do
        adapter :GDBM, :file => 'shared.db'
      end
    end
  end
end
~~~

## More information

* http://yehudakatz.com/2009/02/12/whats-the-point/
* http://yehudakatz.com/2009/02/12/initial-release-of-moneta-unified-keyvalue-store-api/

## Alternatives

* [Horcrux](https://github.com/technoweenie/horcrux): Used at github, supports batch operations but only Memcached backend
* [ToyStore](https://github.com/jnunemaker/toystore): ORM mapper for key/value stores
* [ToyStore Adapter](https://github.com/jnunemaker/adapter): Adapter to key/value stores used by ToyStore, Moneta can be used directly with the ToyStore Memory adapter

## Authors

* Daniel Mendler
* Hannes Georg
* Originally by Yehuda Katz and contributors
