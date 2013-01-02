# Moneta: A unified interface for key/value stores

[![Build Status](https://secure.travis-ci.org/minad/moneta.png?branch=master)](http://travis-ci.org/minad/moneta) [![Dependency Status](https://gemnasium.com/minad/moneta.png?travis)](https://gemnasium.com/minad/moneta) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/minad/moneta)

Moneta provides a standard interface for interacting with various kinds of key/value stores. A short overview of the features:

* Supports a lot of backends (See below)
* Allows a full configuration of the serialization -> compression -> adapter stack using proxies (Similar to [Rack middlewares](http://rack.github.com/))
    * Configurable serialization via `Moneta::Transformer` proxy (Marshal/JSON/YAML and many more)
    * Configurable value compression via `Moneta::Transformer` proxy (Zlib, Snappy, LZMA, ...)
    * Configurable key transformation via `Moneta::Transformer` proxy
* Expiration for all stores (Added via proxy `Moneta::Expires` if not supported natively)
* Atomic incrementation and decrementation for most stores (Method `#increment` and `#decrement`)
* Includes a very simple key/value server (`Moneta::Server`) and client (`Moneta::Adapters::Client`)
* Integration with [Rails](http://rubyonrails.org/), [Rack](http://rack.github.com/), [Sinatra](http://sinatrarb.com/) and [Rack-Cache](https://github.com/rtomayko/rack-cache)

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
    * Simple Samba database TDB (`:TDB`)
* Document databases:
    * CouchDB (`:Couch`)
    * MongoDB (`:Mongo`)
* Moneta network protocols:
    * Moneta key/value client (`:Client` works with `Moneta::Server`)
    * Moneta HTTP/REST client (`:RestClient` works with `Rack::MonetaRest`)
* Other
    * Fog cloud storage which supports Amazon S3, Rackspace, etc. (`:Fog`)
    * Storage which doesn't store anything (`:Null`)

Some of the backends are not exactly based on key/value stores, e.g. the relational ones. These
are useful if you already use the corresponding backend in your application. You get a key/value
store for free then without installing any additional services and you still have the possibility
to upgrade to a real key/value store.

### Backend feature matrix

<table>
<thead style="font-weight:bold"><tr><th>Adapter</th><th>Required gems</th><th>Multi-thread safe<br/>(`Moneta::Lock` not needed)</th><th>Multi-process safe</th><th>Atomic increment</th><th>Native expires</th><th>Persistent</th><th>Description</th></tr></thead>
<tbody>
<tr><td>ActiveRecord</td><td>active_record</td><td>?</td><td>✓</td><td>✓</td><td>✗</td><td>✓</td><td>ActiveRecord ORM</td></tr>
<tr><td>Cassandra</td><td>cassandra</td><td>?</td><td>✓</td><td>✗</td><td>✗</td><td>✓</td><td>Cassandra distributed database</td></tr>
<tr><td>Client</td><td>-</td><td>✗</td><td>✓</td><td>Depends on server</td><td>Depends on server</td><td>Depends on server</td><td>Moneta client adapter</td></tr>
<tr><td>Cookie</td><td>-</td><td>✗</td><td>Memory</td><td>✓</td><td>✓</td><td>✗</td><td>Cookie in memory store</td></tr>
<tr><td>Couch</td><td>couchrest</td><td>?</td><td>✓</td><td>✗</td><td>✗</td><td>✓</td><td>CouchDB database</td></tr>
<tr><td>DataMapper</td><td>dm-core, dm-migrations</td><td>?</td><td>✓</td><td>✓</td><td>✗</td><td>✓</td><td>DataMapper ORM</td></tr>
<tr><td>DBM</td><td>-</td><td>✗</td><td>✗</td><td>✓</td><td>✗</td><td>✓</td><td>Berkeley DB</td></tr>
<tr><td>File</td><td>-</td><td>✓</td><td>✓</td><td>✓</td><td>✗</td><td>✓</td><td>File store</td></tr>
<tr><td>Fog</td><td>fog</td><td>?</td><td>✓</td><td>✗</td><td>✗</td><td>✓</td><td>Fog cloud store</td></tr>
<tr><td>GDBM</td><td>-</td><td>✗</td><td>✗</td><td>✓</td><td>✗</td><td>✓</td><td>GDBM database</td></tr>
<tr><td>HBase</td><td>hbase</td><td>?</td><td>✓</td><td>✗</td><td>✗</td><td>✓</td><td>HBase database</td></tr>
<tr><td>LevelDB</td><td>leveldb</td><td>✗</td><td>✗</td><td>✓</td><td>✗</td><td>✓</td><td>LevelDB database</td></tr>
<tr><td>LocalMemCache</td><td>localmemcache</td><td>?</td><td>✓</td><td>✗</td><td>✗</td><td>✓</td><td>LocalMemCache database</td></tr>
<tr><td>LRUHash</td><td>-</td><td>✗</td><td>Memory</td><td>✓</td><td>✗</td><td>✗</td><td>LRU memory store</td></tr>
<tr><td>Memcached</td><td>dalli or memcached</td><td>?</td><td>✓</td><td>✓</td><td>✓</td><td>✗</td><td>Memcached database</td></tr>
<tr><td>MemcachedDalli</td><td>dalli</td><td>?</td><td>✓</td><td>✓</td><td>✓</td><td>✗</td><td>Memcached database</td></tr>
<tr><td>MemcachedNative</td><td>memcached</td><td>?</td><td>✓</td><td>✓</td><td>✓</td><td>✗</td><td>Memcached database</td></tr>
<tr><td>Memory</td><td>-</td><td>✗</td><td>Memory</td><td>✓</td><td>✗</td><td>✗</td><td>Memory store</td></tr>
<tr><td>Mongo</td><td>mongo</td><td>?</td><td>✓</td><td>✓</td><td>✓</td><td>✓</td><td>MongoDB database</td></tr>
<tr><td>Null</td><td>-</td><td>✓</td><td>✓</td><td>✗</td><td>✗</td><td>✗</td><td>No database</td></tr>
<tr><td>PStore</td><td>-</td><td>✗</td><td>✓</td><td>✓</td><td>✗</td><td>✓</td><td>PStore store</td></tr>
<tr><td>Redis</td><td>redis</td><td>?</td><td>✓</td><td>✓</td><td>✓</td><td>✓</td><td>Redis database</td></tr>
<tr><td>RestClient</td><td>httpi</td><td>?</td><td>✓</td><td>✗</td><td>✗</td><td>Depends on server</td><td>Moneta REST client adapter</td></tr>
<tr><td>Riak</td><td>riak-client</td><td>?</td><td>✓</td><td>✗</td><td>✗</td><td>✓</td><td>Riak database</td></tr>
<tr><td>SDBM</td><td>-</td><td>✗</td><td>✗</td><td>✓</td><td>✗</td><td>✓</td><td>SDBM database</td></tr>
<tr><td>Sequel</td><td>sequel</td><td>?</td><td>✓</td><td>✓</td><td>✗</td><td>✓</td><td>Sequel ORM</td></tr>
<tr><td>Sqlite</td><td>sqlite3</td><td>?</td><td>✓</td><td>✓</td><td>✗</td><td>✓</td><td>Sqlite3 database</td></tr>
<tr><td>TDB</td><td>tdb</td><td>✗</td><td>✓</td><td>✓</td><td>✗</td><td>✓</td><td>TDB database</td></tr>
<tr><td>TokyoCabinet</td><td>tokoycabinet</td><td>✗</td><td>✗</td><td>✓</td><td>✗</td><td>✓</td><td>TokyoCabinet database</td></tr>
<tr><td>YAML</td><td>-</td><td>✗</td><td>✓</td><td>✓</td><td>✗</td><td>✓</td><td>YAML store</td></tr>
</tbody>
</table>

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

The Moneta API is purposely extremely similar to the Hash API with a few minor additions.
There are the additional methods `#load`, `#increment`, `#decrement` and `#close`. Every method takes also a optional
option hash. In order so support an identical API across stores, Moneta does not support iteration or partial matches.

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

#decrement(key, amount = 1, options = {}) increment numeric value. This is a atomic operation
                                          which is not supported by all stores. Returns current value.
                                          This is just syntactic sugar for incrementing with a negative value.

#clear(options = {})                      clear all keys in this store.

#close                                    close database connection.
~~~

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

The Cassandra, Memcached, Redis and Mongo backends supports expires values natively.

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

You can add the expires feature to other backends using the `Moneta::Expires` proxy. But be aware
that expired values are not deleted automatically if they are not looked up.

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
store.increment('counter')     # returns 1, counter created
store.increment('counter')     # returns 2
store.increment('counter', -1) # returns 1
store.increment('counter', 13) # returns 14
store.increment('counter', 0)  # returns 14
store.decrement('counter')     # returns 13
store['name'] = 'Moneta'
store.increment('name')        # raises an Exception
~~~

If you want to access the counter value you have to use raw access to the datastore. This is only important
if you have a `Moneta::Transformer` somewhere in your proxy stack which transforms the values e.g. with `Marshal`.

~~~ ruby
store.increment('counter')          # returns 1, counter created
store.load('counter', :raw => true) # returns 1

store.store('counter', '10', :raw => true)
store.increment('counter') # returns 11
~~~

Fortunately there is a nicer way to do this using some syntactic sugar!

~~~ ruby
store.increment('counter') # returns 1, counter created
store.raw['counter']       # returns 1
store.raw.load('counter')  # returns 1

store.raw['counter'] = '10'
store.increment('counter') # returns 11
~~~

You can also keep the `raw` store in a variable and use it like this:

~~~ ruby
counters = store.raw

counters.increment('counter') # returns 1, counter created
counters['counter']           # returns 1
counters.load('counter')      # returns 1

counters['counter'] = '10'
counters.increment('counter') # returns 11
~~~

### Syntactic sugar and option merger

For raw data access as described before the class `Moneta::OptionMerger` is used. It works like this:

~~~ ruby
# All methods after 'with' get the options passed
store.with(:raw => true).load('key')

# You can also specify the methods
store.with(:raw => true, :only => :load).load('key')
store.with(:raw => true, :except => [:key?, :increment]).load('key')

# Syntactic sugar for raw access
store.raw.load('key')

# Access substore where all keys get a prefix
substore = store.prefix('sub')
substore['key'] = 'value'
store['key']    # returns nil
store['subkey'] # returns 'value'

# Set expiration time for all keys
short_lived_store = store.expires(60)
short_lived_store['key'] = 'value'
~~~

## Framework Integration

Inspired by [redis-store](https://github.com/jodosha/redis-store) there exist integration classes for [Rails](http://rubyonrails.org/), [Rack](http://rack.github.com/) and [Rack-Cache](https://github.com/rtomayko/rack-cache). You can also use all the Rack middlewares together with the [Sinatra](http://sinatrarb.com/) framework. There exist the following integration classes:

* Rack and Sinatra
    * `Rack::Session::Moneta` is a Rack middleware to use Moneta for storing sessions
    * `Rack::MonetaStore` is a Rack middleware which places a Moneta store in the environment and enables per-request caching
    * `Rack::MonetaCookies` is a Rack middleware which uses Moneta to store cookies
    * `Rack::MonetaRest` is a Rack application which exposes a Moneta store via REST/HTTP
    * `Rack::Cache::Moneta` provides meta and entity stores for Rack-Cache
* Rails
    * `ActionDispatch::Session::MonetaStore` is a Rails middleware to use Moneta for storing sessions
    * `ActiveSupport::Cache::MonetaStore` is a Rails cache implementation which uses a Moneta store as backend

### Rack session store

You can use Moneta as a [Rack](http://rack.github.com/) session store. Use it in your `config.ru` like this:

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

### Rack Moneta middleware

There is a simple middleware which places a Moneta store in the Rack environment at `env['rack.moneta_store']`. It supports per-request
caching if you add the option `:cache => true`. Use it in your `config.ru` like this:

~~~ ruby
# Add Rack::MonetaStore somewhere in your rack stack
use Rack::MonetaStore, :Memory, :cache => true

run lambda do |env|
  env['rack.moneta_store'] # is a Moneta store with per-request caching
end

# Pass it a block like the one passed to Moneta.build
use Rack::MonetaStore do
  use :Transformer, :value => :zlib
  adapter :Cookie
end

run lambda do |env|
  env['rack.moneta_store'] # is a Moneta store without caching
end
~~~

### Rack REST server

If you want to expose your Moneta key/value store via HTTP, you can use the Rack/Moneta REST service. Use it in your `config.ru` like this:

~~~ ruby
require 'rack/moneta_rest'

map '/moneta' do
  run Rack::MonetaRest.new(:Memory)
end

# Or pass it a block like the one passed to Moneta.build
run Rack::MonetaRest.new do
  use :Transformer, :value => :zlib
  adapter :Memory
end
~~~

### Rack cache

You can use Moneta as a [Rack-Cache](https://github.com/rtomayko/rack-cache) store. Use it in your `config.ru` like this:

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

## Advanced

### Build your own key value server

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

If you want to go further, you might want to take a look at `Moneta::Server` and `Moneta::Adapters::Client` which
are used by `Moneta::Shared` and provide the networking communication. But be aware that they are experimental
and subjected to change. They provide an acceptable performance (for being ruby only), but don't have a stable protocol yet.

You might wonder why I didn't use [DRb](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/drb/rdoc/DRb.html) to implement server and client -
in fact my first versions used it, but with much worse performance and it was real fun to implement the networking directly :)
There is still much room for improvement and experiments, try [EventMachine](http://eventmachine.rubyforge.org/),
try [Kgio](http://bogomips.org/kgio/), ...

### ToyStore ORM

If you want something more advanced to handle your objects and relations,
use John Nunemaker's [ToyStore](https://github.com/jnunemaker/toystore) which works
together with Moneta. Assuming that `Person` is a `ToyStore::Object` you can
add persistence using Moneta as follows:

~~~ ruby
# Use the Moneta Redis backend
Person.adapter :memory, Moneta.new(:Redis)
~~~

## Testing and Benchmarks

Testing is done using [Travis-CI](http://travis-ci.org/minad/moneta). Currently we support Ruby 1.8.7 and 1.9.3.

Benchmarks for each store are done on [Travis-CI](http://travis-ci.org/minad/moneta) for each build. Take a look there
to compare the speed of the different key value stores for different key/value sizes and size distributions.
Feel free to add your own configurations! The impact of Moneta should be minimal since it is only a thin layer
on top of the different stores.

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
