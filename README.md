# Moneta: A unified interface for key/value stores

[![Gem Version](https://badge.fury.io/rb/moneta.svg)](http://rubygems.org/gems/moneta) [![Build Status](https://secure.travis-ci.org/moneta-rb/moneta.svg?branch=master)](http://travis-ci.org/moneta-rb/moneta) [![Code Climate](https://codeclimate.com/github/moneta-rb/moneta.svg)](https://codeclimate.com/github/moneta-rb/moneta) [![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=min4d&url=https://github.com/moneta-rb/moneta&title=Moneta&language=&tags=github&category=software)

Moneta provides a standard interface for interacting with various kinds of key/value stores. Moneta supports the well-known
NoSQL and document based stores.

A short overview of the features:

* Supports a lot of backends with consistent behaviour (See below)
* Allows a full configuration of the serialization -> compression -> adapter stack using proxies (Similar to [Rack middlewares](http://rack.github.com/))
    * Configurable serialization via `Moneta::Transformer` proxy (Marshal/JSON/YAML and many more)
    * Configurable value compression via `Moneta::Transformer` proxy (Zlib, Snappy, LZMA, ...)
    * Configurable key transformation via `Moneta::Transformer` proxy
* Expiration for all stores (Added via proxy `Moneta::Expires` if not supported natively)
* Atomic operations
    * Atomic incrementation and decrementation for most stores (Method `#increment` and `#decrement`)
    * Atomic creation of entries (Method `#create`)
    * Shared/distributed database-wide synchronization primitives `Moneta::Mutex` and `Moneta::Semaphore`
* Includes a simple pure-ruby key/value server (`Moneta::Server`) and client (`Moneta::Adapters::Client`)
* Integration with [Rails](http://rubyonrails.org/), [Rack](http://rack.github.com/)/[Rack-Cache](https://github.com/rtomayko/rack-cache), [Sinatra](http://sinatrarb.com/), [Padrino](http://padrinorb.com) and [Ramaze](http://ramaze.net/).

If you are not yet convinced, you might ask why? What are the goals of the project?

* Get people started quickly with key/value stores! Therefore all the adapters are included in the gem and you are ready to go. [Tilt](https://github.com/rtomayko/tilt) does the
same for template languages.
* Make it easy to compare different key/value stores and benchmark them
* To hide a lot of different and maybe complex APIs behind one well-designed and simple Moneta API
* Give people a starting point or example code to start working with their favourite key/value store. Feel free to copy code, please mention Moneta then :)
* Create a reusable piece of code, since similar things are solved over and over again ([Rails](http://rubyonrails.org/) brings its own cache stores, and many frameworks do the same...)

Moneta is tested thoroughly using [Travis-CI](http://travis-ci.org/moneta-rb/moneta).

------

## Getting started

Install Moneta via Rubygems

~~~
$ gem install moneta
~~~

or add it to your Gemfile

~~~ ruby
gem 'moneta'
~~~

Now you are ready to go:

~~~ ruby
require 'moneta'

# Create a simple file store
store = Moneta.new(:File, dir: 'moneta')

# Store some entries
store['key'] = 'value'

# Read entry
store.key?('key') # returns true
store['key'] # returns 'value'

store.close
~~~

------

## Links

* Source: <http://github.com/moneta-rb/moneta>
* Bugs:   <http://github.com/moneta-rb/moneta/issues>
* Tests and benchmarks: <http://travis-ci.org/moneta-rb/moneta>
* API documentation:
    * Latest Gem: <http://rubydoc.info/gems/moneta/frames>
    * GitHub master: <http://rubydoc.info/github/moneta-rb/moneta/master/frames>

------

## Supported backends

Out of the box, it supports the following backends. Use the backend name symbol in the Moneta constructor (e.g. `Moneta.new(:Memory)`).

* Memory:
    * In-memory store (`:Memory`)
    * LRU hash - prefer this over :Memory! (`:LRUHash`)
    * [LocalMemCache](http://localmemcache.rubyforge.org/) (`:LocalMemCache`)
    * [Memcached](http://memcached.org/) store (`:Memcached`, `:MemcachedNative` and `:MemcachedDalli`)
* Relational Databases:
    * [DataMapper](http://datamapper.org/) (`:DataMapper`)
    * [ActiveRecord](https://rubygems.org/gems/activerecord) (`:ActiveRecord`)
    * [Sequel](http://sequel.rubyforge.org/) (`:Sequel`)
    * [Sqlite3](http://sqlite.org/) (`:Sqlite`)
* Filesystem:
    * [PStore](http://ruby-doc.org/stdlib/libdoc/pstore/rdoc/PStore.html) (`:PStore`)
    * [YAML](http://www.ruby-doc.org/stdlib/libdoc/yaml/rdoc/YAML/Store.html) store (`:YAML`)
    * Filesystem directory store (`:File`)
    * Filesystem directory store which spreads files in subdirectories using md5 hash (`:HashFile`)
* Key/value databases:
    * [Berkeley DB using DBM interface or NDBM (Depends on Ruby environment)](http://www.ruby-doc.org/stdlib/libdoc/dbm/rdoc/DBM.html) (`:DBM`)
    * [Cassandra](http://cassandra.apache.org/) (`:Cassandra`)
    * [Daybreak](http://propublica.github.com/daybreak/) (`:Daybreak`)
    * [GDBM](http://www.ruby-doc.org/stdlib/libdoc/gdbm/rdoc/GDBM.html) (`:GDBM`)
    * [HBase](http://hbase.apache.org/) (`:HBase`)
    * [LevelDB](http://code.google.com/p/leveldb/) (`:LevelDB`)
    * [LMDB](http://symas.com/mdb/) (`:LMDB`)
    * [Redis](http://redis.io/) (`:Redis`)
    * [Riak](http://docs.basho.com/) (`:Riak`)
    * [SDBM](http://www.ruby-doc.org/stdlib/libdoc/sdbm/rdoc/SDBM.html) (`:SDBM`)
    * [KyotoCabinet](http://fallabs.com/kyotocabinet/) (`:KyotoCabinet`)
    * [TokyoCabinet](http://fallabs.com/tokyocabinet/) (`:TokyoCabinet`)
    * [TokyoTyrant](http://fallabs.com/tokyotyrant/) (`:TokyoTyrant`)
    * [Simple Samba database TDB](http://tdb.samba.org/) (`:TDB`)
* Document databases:
    * [CouchDB](http://couchdb.apache.org/) (`:Couch`)
    * [MongoDB](http://www.mongodb.org/) (`:Mongo`, `:MongoOffical` or `:MongoMoped`)
* Moneta network protocols:
    * Moneta key/value client (`:Client` works with `Moneta::Server`)
    * Moneta HTTP/REST client (`:RestClient` works with `Rack::MonetaRest`)
* Other
    * [Fog](http://fog.io/) cloud storage which supports Amazon S3, Rackspace, etc. (`:Fog`)
    * Storage which doesn't store anything (`:Null`)

Some of the backends are not exactly based on key/value stores, e.g. the relational ones. These
are useful if you already use the corresponding backend in your application. You get a key/value
store for free then without installing any additional services and you still have the possibility
to upgrade to a real key/value store.

### Backend feature matrix

__NOTE:__ <a name="backend-matrix"></a>The backend matrix is much more readable on rubydoc.info than on github. [Go there!](http://rubydoc.info/github/moneta-rb/moneta/master/file/README.md#backend-matrix)

<table class="backend-feature-matrix">
<tr><th>Adapter</th><th>Required gems</th><th class="feature">Multi-thread safe<sup>1</sup></th><th class="feature">Multi-process safe<sup>2</sup></th><th class="feature">Atomic increment<sup>3</sup></th><th class="feature">Atomic create<sup>4</sup></th><th class="feature">Native expires<sup>5</sup></th><th class="feature">Persistent</th><th class="feature">Key Traversal</th><th class="feature">Bulk read<sup>6</sup></th><th class="feature">Bulk write<sup>7</sup></th><th>Description</th></tr>

<tr><th colspan="2">Persistent stores</th><th colspan="10"></th></tr>

<tr><td>Mongo</td><td>mongo or moped</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td><a href="http://www.mongodb.org/">MongoDB</a> database</td></tr>

<tr><td>MongoOfficial</td><td>mongo</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td><a href="http://www.mongodb.org/">MongoDB</a> database</td></tr>

<tr><td>MongoMoped</td><td>moped</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td><a href="http://www.mongodb.org/">MongoDB</a> database</td></tr>

<tr><td>Redis</td><td>redis</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td><a href="http://redis.io/">Redis</a> database</td></tr>

<tr><td>ActiveRecord</td><td>activerecord</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td><a href="https://rubygems.org/gems/activerecord">ActiveRecord</a> ORM</td></tr>

<tr><td>File</td><td>-</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature no">✗</td><td>File store</td></tr>

<tr><td>LMDB</td><td>lmdb</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td><a href="http://symas.com/mdb/">Symas Lightning Memory-Mapped Database (LMDB)</a></td></tr>

<tr><td>Sequel</td><td>sequel</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td><a href="http://sequel.rubyforge.org/">Sequel</a> ORM</td></tr>

<tr><td>TokyoTyrant</td><td>tokyotyrant or ruby-tokyotyrant</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature no">✗</td><td><a href="http://fallabs.com/tokyotyrant/">TokyoTyrant</a> database</td></tr>

<tr><td>PStore</td><td>-</td><td class="feature no">✗</td><td class="feature yes">✓<sup>8</sup></td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td><a href="http://ruby-doc.org/stdlib/libdoc/pstore/rdoc/PStore.html">PStore</a> store</td></tr>

<tr><td>YAML</td><td>-</td><td class="feature no">✗</td><td class="feature yes">✓<sup>8</sup></td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature no">✗</td><td><a href="http://www.ruby-doc.org/stdlib/libdoc/yaml/rdoc/YAML/Store.html">YAML</a> store</td></tr>

<tr><td>Sqlite</td><td>sqlite3</td><td class="feature unknown">?</td><td class="feature yes">✓<sup>8</sup></td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td><a href="http://sqlite.org/">Sqlite3</a> database</td></tr>

<tr><td>Daybreak</td><td>daybreak</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td>Incredibly fast pure-ruby key/value store <a href="http://propublica.github.com/daybreak/">Daybreak</a></td></tr>

<tr><td>DBM</td><td>-</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td><a href="http://www.ruby-doc.org/stdlib/libdoc/dbm/rdoc/DBM.html">Berkeley DB using DBM interface or NDBM (Depends on Ruby environment)</a></td></tr>

<tr><td>GDBM</td><td>-</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td><a href="http://www.ruby-doc.org/stdlib/libdoc/gdbm/rdoc/GDBM.html">GDBM</a> database</td></tr>

<tr><td>LevelDB</td><td>leveldb</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td><a href="http://code.google.com/p/leveldb/">LevelDB</a> database</td></tr>

<tr><td>SDBM</td><td>-</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td><a href="http://www.ruby-doc.org/stdlib/libdoc/sdbm/rdoc/SDBM.html">SDBM</a> database</td></tr>

<tr><td>TDB</td><td>tdb</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature no">✗</td><td><a href="http://tdb.samba.org/">TDB</a> database</td></tr>

<tr><td>KyotoCabinet</td><td>kyotocabinet-ruby or kyotocabinet-ruby-reanimated</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td><a href="http://fallabs.com/kyotocabinet/">KyotoCabinet</a> database</td></tr>

<tr><td>TokyoCabinet</td><td>tokyocabinet</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature no">✗</td><td><a href="http://fallabs.com/tokyocabinet/">TokyoCabinet</a> database</td></tr>

<tr><td>DataMapper</td><td>dm-core, dm-migrations</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature no">✗</td><td><a href="http://datamapper.org/">DataMapper</a> ORM</td></tr>

<tr><td>Couch</td><td>faraday, multi_json</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td><a href="http://couchdb.apache.org/">CouchDB</a> database</td></tr>

<tr><td>HBase</td><td>hbaserb</td><td class="feature unknown">?</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature no">✗</td><td><a href="http://hbase.apache.org/">HBase</a> database</td></tr>

<tr><td>Cassandra</td><td>cassandra</td><td class="feature unknown">?</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td><a href="http://cassandra.apache.org/">Cassandra</a> distributed database</td></tr>

<tr><td>LocalMemCache</td><td>localmemcache</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature no">✗</td><td><a href="http://localmemcache.rubyforge.org/">LocalMemCache</a> database</td></tr>

<tr><td>Fog</td><td>fog</td><td class="feature unknown">?</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature no">✗</td><td><a href="http://fog.io/">Fog</a> cloud store</td></tr>

<tr><td>Riak</td><td>riak-client</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature no">✗</td><td><a href="http://docs.basho.com/">Riak</a> database</td></tr>

<tr><th colspan="2">Non-persistent stores</th><th colspan="10"></th></tr>

<tr><td>MemcachedDalli</td><td>dalli</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗<sup>9</sup></td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td><a href="http://memcached.org/">Memcached</a> database with Dalli library</td></tr>

<tr><td>Memcached</td><td>dalli or memcached</td><td class="feature unknown">?</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗<sup>9</sup></td><td class="feature no">✗</td><td class="feature unknown">?</td><td class="feature unknown">?</td><td><a href="http://memcached.org/">Memcached</a> database</td></tr>

<tr><td>MemcachedNative</td><td>memcached</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗<sup>9</sup></td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature no">✗</td><td>Memcached database with native library</td></tr>

<tr><td>Cookie</td><td>-</td><td class="feature no">✗</td><td class="feature yes">✓<sup>10</sup></td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature no">✗</td><td>Cookie in memory store</td></tr>

<tr><td>LRUHash</td><td>-</td><td class="feature no">✗</td><td class="feature yes">✓<sup>10</sup></td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature no">✗</td><td>LRU memory store</td></tr>

<tr><td>Memory</td><td>-</td><td class="feature no">✗</td><td class="feature yes">✓<sup>10</sup></td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td>Memory store</td></tr>

<tr><td>Null</td><td>-</td><td class="feature yes">✓</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature no">✗</td><td>No database</td></tr>

<tr><th colspan="2">Network clients</th><th colspan="10"></th></tr>

<tr><td>Client</td><td>-</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature unknown">?<sup>11</sup></td><td class="feature unknown">?<sup>11</sup></td><td class="feature unknown">?<sup>11</sup></td><td class="feature unknown">?<sup>11</sup></td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature no">✗</td><td>Moneta client adapter</td></tr>

<tr><td>RestClient</td><td>-</td><td class="feature no">✗</td><td class="feature yes">✓</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature unknown">?<sup>11</sup></td><td class="feature no">✗</td><td class="feature no">✗</td><td class="feature no">✗</td><td>Moneta REST client adapter</td></tr>

</table>

1. Make adapters thread-safe by using `Moneta::Lock` or by passing the option `threadsafe: true` to `Moneta#new`. There is also `Moneta::Pool` which can be used to share a store between multiple threads if the store is multi-process safe. I recommend to add the option `:threadsafe` to ensure thread-safety since for example under JRuby and Rubinius even the basic datastructures are not thread safe due to the lack of a global interpreter lock (GIL). This differs from MRI where some adapters might appear thread safe already but only due to the GIL.
2. Share a Moneta store between multiple processes using `Moneta::Shared` (See below).
3. If a store provides atomic increment it can be used with `Moneta::Semaphore`. You can add weak `#increment` support using the `Moneta::WeakIncrement` proxy.
4. If a store provides atomic creation it can be used with `Moneta::Mutex`. You can add weak `#create` support using the `Moneta::WeakCreate` proxy.
5. Add expiration support by using `Moneta::Expires` or by passing the option `expires: true` to `Moneta#new`.
6. This indicates that there is some performance gain when fetching multiple values at once using `#values_at`/`#fetch_values` or `#slice`. For instance, the `MGET` instruction in Redis, or the ability to retrieve several rows in one query in SQL.
7. This indicates that there is some performance gain when storing multiple key/value pairs at once using `#merge!`/`#update`.
8. Sqlite/YAML/PStore are multiprocess safe, but the performance suffers badly since the whole database file must be locked for writing. Use a key/value server if you want multiprocess concurrency!
9. There are some servers which use the memcached protocol but which are persistent (e.g. [MemcacheDB](http://memcachedb.org/), [Kai](http://sourceforge.net/apps/mediawiki/kai), [IronCache](http://dev.iron.io/cache/reference/memcache/), [Roma](https://github.com/roma/roma/tree), [Flare](http://labs.gree.jp/Top/OpenSource/Flare-en.html) and [Kumofs](https://github.com/etolabo/kumofs))
10. Store is multi-process safe because it is an in-memory store, values are not shared between multiple processes
11. Depends on server

------

## Proxies

In addition it supports proxies (Similar to [Rack middlewares](http://rack.github.com/)) which
add additional features to storage backends:

* `Moneta::Proxy` and `Moneta::Wrapper` proxy base classes
* `Moneta::Expires` to add expiration support to stores which don't support it natively. Add it in the builder using `use :Expires`.
* `Moneta::Stack` to stack multiple stores (Read returns result from first where the key is found, writes go to all stores). Add it in the builder using `use(:Stack) {}`.
* `Moneta::Transformer` transforms keys and values (Marshal, YAML, JSON, Base64, MD5, ...). Add it in the builder using `use :Transformer`.
* `Moneta::Cache` combine two stores, one as backend and one as cache (e.g. `Moneta::Adapters::File` + `Moneta::Adapters::LRUHash`). Add it in the builder using `use(:Cache) {}`.
* `Moneta::Lock` to make store thread safe. Add it in the builder using `use :Lock`.
* `Moneta::Pool` to create a pool of stores as a means of making the store thread safe. Add it in the builder using `use(:Pool) {}`.
* `Moneta::Logger` to log database accesses. Add it in the builder using `use :Logger`.
* `Moneta::Shared` to share a store between multiple processes. Add it in the builder using `use(:Shared) {}`.
* `Moneta::WeakIncrement` and `Moneta::WeakCreate` to add `#create` and `#increment` support without atomicity (weak) to stores which don't support it.

### Serializers and compressors (`Moneta::Transformer`)

Supported serializers:

* BEncode (`:bencode`)
* BERT (`:bert`)
* BSON (`:bson`)
* JSON (`:json`)
* Marshal (`:marshal`)
* MessagePack (`:msgpack`)
* Ox (`:ox`)
* PHP (`:php`)
* TNetStrings (`:tnet`)
* YAML (`:yaml`)

Supported value compressors:

* Bzip2 (`:bzip2`)
* LZ4 (`:lz4`)
* LZMA (`:lzma`)
* LZO (`:lzo`)
* Snappy (`:snappy`)
* QuickLZ (`:quicklz`)
* Zlib (`:zlib`)

Supported encoders:

* Base64 (RFC 2045; `:base64`)
* URL-safe Base64 (RFC 4648; `:urlsafe_base64`)
* Url escape (`:escape`)
* Hexadecimal (`:hex`)
* QP (`:qp`)
* UUEncode (`:uuencode`)

Special transformers:

* Digests (MD5, Shas, CityHash, ...)
* Add prefix to keys (`:prefix`)
* HMAC to verify values (`:hmac`, useful for `Rack::MonetaCookies`)

------

## Moneta API

The Moneta API is purposely extremely similar to the Hash API with a few minor additions.
Every method takes also a optional option hash. In order so support an identical API across stores,
Moneta does not support iteration or partial matches.

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

#increment(key, amount = 1, options = {}) increment numeric value. This is an atomic operation
                                          which is not supported by all stores. Returns current value.

#decrement(key, amount = 1, options = {}) increment numeric value. This is an atomic operation
                                          which is not supported by all stores. Returns current value.
                                          This is just syntactic sugar for incrementing with a negative value.

#create(key, value, options = {})         create entry. This is an atomic operation which is not supported by all stores.
                                          Returns true if the value was created.

#clear(options = {})                      clear all keys in this store.

#close                                    close database connection.

#features                                 return array of features, e.g. [:create, :expires, :increment]

#supports?(feature)                       returns true if store supports a given feature
~~~

### Creating a Store

There is a simple interface to create a store using `Moneta.new`. You will
get automatic key and value serialization which is provided by `Moneta::Transformer`.
This allows you to store arbitrary Ruby objects. You can tune some options
when you call `Moneta.new`. However for very fine tuning use `Moneta.build`.

~~~ ruby
store = Moneta.new(:Memcached, server: 'localhost:11211')
store['key'] = 'value'
store['hash_key'] = {a: 1, b: 2}
store['object_key'] = MarshallableRubyObject.new
~~~

If you want to have control over the proxies, you have to use `Moneta.build`:

~~~ ruby
store = Moneta.build do
  # Adds expires proxy
  use :Expires

  # Transform key using Marshal and Base64 and value using Marshal
  use :Transformer, key: [:marshal, :base64], value: :marshal

  # IMPORTANT: adapter must be defined last for the builder to function properly.

  # Memory backend
  adapter :Memory
end
~~~

You can also directly access the underlying adapters if you don't want
to use the Moneta stack.

~~~ ruby
db = Moneta::Adapters::File.new(dir: 'directory')
db['key'] = {a: 1, b: 2} # This will fail since you can only store Strings

# However for Mongo and Couch this works
# The hash will be mapped directly to a Mongo/Couch document.
db = Moneta::Adapters::Couch.new
db['key'] = {a: 1, b: 2}

db = Moneta::Adapters::Mongo.new
db['key'] = {a: 1, b: 2}
~~~

### Expiration

The Cassandra, Memcached, Redis and Mongo backends support expiration natively.

~~~ ruby
cache = Moneta::Adapters::Memcached.new

# Or using the builder...
cache = Moneta.build do
  adapter :Memcached
end

# Expires in 60 seconds
cache.store(key, value, expires: 60)

# Never expire
cache.store(key, value, expires: 0)
cache.store(key, value, expires: false)

# Update expires time if value is found
cache.load(key, expires: 30)
cache.key?(key, expires: 30)

# Or remove the expiration if found
cache.load(key, expires: false)
cache.key?(key, expires: 0)
~~~

You can add the expires feature to other backends using the `Moneta::Expires` proxy. But be aware
that expired values are not deleted automatically if they are not looked up.

~~~ ruby
# Using the :expires option
cache = Moneta.new(:File, dir: '...', expires: true)

# or manually by using the proxy...
cache = Moneta::Expires.new(Moneta::Adapters::File.new(dir: '...'))

# or using the builder...
cache = Moneta.build do
  use :Expires
  adapter :File, dir: '...'
end
~~~

### Atomic operations

#### Atomic incrementation and raw access

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
store.load('counter', raw: true) # returns 1

store.store('counter', '10', raw: true)
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

#### Atomic create

The stores support the `#create` which allows atomic creation of entries. `#create` returns true
if the value was created.

~~~ ruby
store.create('key', 'value') # returns true
store.create('key', 'other value') # returns false
~~~

#### Shared/distributed synchronization primitives

Moneta provides shared/distributed synchronization primitives which are shared database-wide between
all clients.

`Moneta::Mutex` allows a single thread to enter a critical section.

~~~ ruby
mutex = Moneta::Mutex.new(store, 'mutex_key')

mutex.synchronize do
   mutex.locked? # returns true

   # Synchronized access to counter
   store['counter'] += 1
end

begin
  mutex.lock
  mutex.locked? # returns true
  # ...
ensure
  mutex.unlock
end
~~~

`Moneta::Semaphore` allows `max_concurrent` threads to enter a critical section.

~~~ ruby
semaphore = Moneta::Semaphore.new(store, 'semaphore_counter', max_concurrent)

semaphore.synchronize do
   semaphore.locked? # returns true
   # ...
end

begin
  semaphore.enter
  semaphore.locked? # returns true
  # ...
ensure
  semaphore.leave
end
~~~

#### Weak atomic operations

If an underlying adapter doesn't provide atomic `#create` or `#increment` and `#decrement` you can
use the proxies `Moneta::WeakIncrement` and `Moneta::WeakCreate` to add support without atomicity.

But then you have to ensure that the store is not shared by multiple processes and thread-safety is
provided by `Moneta::Lock`.

### Syntactic sugar and option merger

For raw data access as described before the class `Moneta::OptionMerger` is used. It works like this:

~~~ ruby
# All methods after 'with' get the options passed
store.with(raw: true).load('key')

# You can also specify the methods
store.with(raw: true, only: :load).load('key')
store.with(raw: true, except: [:key?, :increment]).load('key')

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

### Add proxies to existing store

You can add proxies to an existing store. This is useful if you want to compress only a few values for example.

~~~ ruby
compressed_store = store.with(prefix: 'compressed') do
  use :Transformer, value: :zlib
end

store['key'] = 'this value will not be compressed'
compressed_store['key'] = 'value will be compressed'
~~~

------

## Framework Integration

Inspired by [redis-store](https://github.com/jodosha/redis-store) there exist integration classes for [Rails](http://rubyonrails.org/) and [Rack](http://rack.github.com/)/[Rack-Cache](https://github.com/rtomayko/rack-cache). You can also use all the Rack middlewares together with Rails and the [Sinatra](http://sinatrarb.com/) framework. There exist the following integration classes:

* [Rack](http://rack.github.com/), [Rails](http://rubyonrails.org/) and [Sinatra](http://sinatrarb.com/)
    * `Rack::Session::Moneta` is a Rack middleware to use Moneta for storing sessions
    * `Rack::MonetaStore` is a Rack middleware which places a Moneta store in the environment and enables per-request caching
    * `Rack::MonetaCookies` is a Rack middleware which uses Moneta to store cookies
    * `Rack::MonetaRest` is a Rack application which exposes a Moneta store via REST/HTTP
    * `Rack::Cache::Moneta` provides meta and entity stores for Rack-Cache
* [Rails](http://rubyonrails.org/)
    * `ActionDispatch::Session::MonetaStore` is a Rails middleware to use Moneta for storing sessions
    * `ActiveSupport::Cache::MonetaStore` is a Rails cache implementation which uses a Moneta store as backend
* [Ramaze](http://ramaze.net/)
    * `Ramaze::Cache::Moneta` is integrated into the Ramaze project and allows Ramaze to use
      Moneta as caching store
* [Padrino](http://padrinorb.com) adopted Moneta to replace their cache stores in padrino-cache.

### Rack

#### Session store

You can use Moneta as a [Rack](http://rack.github.com/) session store. Use it in your `config.ru` like this:

~~~ ruby
require 'rack/session/moneta'

# Use only the adapter name
use Rack::Session::Moneta, store: :Redis

# Use Moneta.new
use Rack::Session::Moneta, store: Moneta.new(:Memory, expires: true)

# Set rack options
use Rack::Session::Moneta, key: 'rack.session',
domain: 'foo.com',
path: '/',
expire_after: 2592000,
store: Moneta.new(:Memory, expires: true)

# Use the Moneta builder
use Rack::Session::Moneta do
  use :Expires
  adapter :Memory
end
~~~

#### Moneta middleware

There is a simple middleware which places a Moneta store in the Rack environment at `env['rack.moneta_store']`. It supports per-request
caching if you add the option `cache: true`. Use it in your `config.ru` like this:

~~~ ruby
require 'rack/moneta_store'

# Add Rack::MonetaStore somewhere in your rack stack
use Rack::MonetaStore, :Memory, cache: true

run lambda { |env|
  env['rack.moneta_store'] # is a Moneta store with per-request caching
}

# Pass it a block like the one passed to Moneta.build
use Rack::MonetaStore do
  use :Transformer, value: :zlib
  adapter :Cookie
end

run lambda { |env|
  env['rack.moneta_store'] # is a Moneta store without caching
}
~~~

#### REST server

If you want to expose your Moneta key/value store via HTTP, you can use the Rack/Moneta REST service. Use it in your `config.ru` like this:

~~~ ruby
require 'rack/moneta_rest'

map '/moneta' do
  run Rack::MonetaRest.new(:Memory)
end

# Or pass it a block like the one passed to Moneta.build
run Rack::MonetaRest.new do
  use :Transformer, value: :zlib
  adapter :Memory
end
~~~

#### Rack-Cache

You can use Moneta as a [Rack-Cache](https://github.com/rtomayko/rack-cache) store. Use it in your `config.ru` like this:

~~~ ruby
require 'rack/cache/moneta'

use Rack::Cache,
      metastore:   'moneta://Memory?expires=true',
      entitystore: 'moneta://Memory?expires=true'

# Or used named Moneta stores
Rack::Cache::Moneta['named_metastore'] = Moneta.build do
  use :Expires
  adapter :Memory
end
use Rack::Cache,
      metastore: 'moneta://named_metastore',
      entity_store: 'moneta://named_entitystore'
~~~

#### Cookies

Use Moneta to store cookies in [Rack](http://rack.github.com/). It uses the `Moneta::Adapters::Cookie`. You might
wonder what the purpose of this store or Rack middleware is: It makes it possible
to use all the transformers on the cookies (e.g. `:prefix`, `:marshal` and `:hmac` for value verification).

~~~ ruby
require 'rack/moneta_cookies'

use Rack::MonetaCookies, domain: 'example.com', path: '/path'
run lambda { |env|
  req = Rack::Request.new(env)
  req.cookies #=> is now a Moneta store!
  env['rack.request.cookie_hash'] #=> is now a Moneta store!
  req.cookies['key'] #=> retrieves 'key'
  req.cookies['key'] = 'value' #=> sets 'key'
  req.cookies.delete('key') #=> removes 'key'
  [200, {}, []]
}
~~~

### Rails

#### Session store

Add the session store in your application configuration `config/environments/*.rb`.

~~~ ruby
require 'action_dispatch/middleware/session/moneta_store'

# Only by adapter name
config.cache_store :moneta_store, store: :Memory

# Use Moneta.new
config.cache_store :moneta_store, store: Moneta.new(:Memory)

# Use the Moneta builder
config.cache_store :moneta_store, store: Moneta.build do
  use :Expires
  adapter :Memory
end
~~~

#### Cache store

Add the cache store in your application configuration `config/environments/*.rb`. Unfortunately the
Moneta cache store doesn't support matchers. If you need these features use a different server-specific implementation.

~~~ ruby
require 'active_support/cache/moneta_store'

# Only by adapter name
config.cache_store :moneta_store, store: :Memory

# Use Moneta.new
config.cache_store :moneta_store, store: Moneta.new(:Memory)

# Use the Moneta builder
config.cache_store :moneta_store, store: Moneta.build do
  use :Expires
  adapter :Memory
end
~~~

### Padrino

[Padrino](http://padrinorb.com/) adopted Moneta to replace their cache stores in padrino-cache. You use it like this

~~~ ruby
# Global Padrino caching
# Don't forget the expires: [true, Integer] if you want expiration support!
Padrino.cache = Moneta.new(:Memory, expires: true)

# Application caching
# Don't forget the expires: [true, Integer] if you want expiration support!
set :cache, Moneta.new(:Memory, expires: true)
~~~

## Advanced

### Build your own key value server

You can use Moneta to build your own key/value server which is shared between
multiple processes. If you run the following code in two different processes,
they will share the same data which will also be persistet in the database `shared.db`.

~~~ ruby
require 'moneta'

store = Moneta.build do
  use :Transformer, key: :marshal, value: :marshal
  use :Shared do
    use :Cache do
      cache do
        adapter :LRUHash
      end
      backend do
        adapter :GDBM, file: 'shared.db'
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

------

## Testing and Benchmarks

Testing is done using [Travis-CI](http://travis-ci.org/moneta-rb/moneta). Currently we support Ruby >= 1.9.3.

Benchmarks for each store are done on [Travis-CI](http://travis-ci.org/moneta-rb/moneta) for each build. Take a look there
to compare the speed of the different key value stores for different key/value sizes and size distributions.
Feel free to add your own configurations! The impact of Moneta should be minimal since it is only a thin layer
on top of the different stores.


------

## How to contribute?

Always feel free to open an issue on
https://github.com/moneta-rb/moneta/issues if something doesn't work
as you expect it to work. Feedback is also very welcome!

My only request about patches is that you please try
to test them before submitting.

### Contribute an adapter

If you want support for another adapter you can at first at it to the list of
missing adapters at https://github.com/moneta-rb/moneta/issues/16

If you choose to implement an adapter please also add tests. Usually you
only have to add a few lines to `script/generate-specs` to generate appropriate
tests for your adapter. Please check also if travis.yml needs changes, for example
if you need to start additional services.

Check if the default settings in Moneta#new are appropriate for your adapter. If
not specify a better one.

Don't forget to edit the README.md and the CHANGES.

------

## Alternatives

* [Horcrux](https://github.com/technoweenie/horcrux): Used at github, supports batch operations but only Memcached backend
* [ActiveSupport::Cache::Store](http://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html): The Rails cache store abstraction
* [ToyStore](https://github.com/jnunemaker/toystore): ORM mapper for key/value stores
* [ToyStore Adapter](https://github.com/jnunemaker/adapter): Adapter to key/value stores used by ToyStore, Moneta can be used directly with the ToyStore Memory adapter
* [Cache](https://github.com/seamusabshere/cache): Rubygem cache wraps Memcached and Redis
* [Ramaze::Cache](http://ramaze.net/documentation/Innate/Cache.html): Cache stores of the Ramaze framework with support for LocalMemCache, Memcached, Sequel, Redis, ...

------

## Authors

* [Daniel Mendler](https://github.com/minad)
* [Hannes Georg](https://github.com/hannesg)
* [Alastair Pharo](https://github.com/asppsa)
* Originally by [Yehuda Katz](https://github.com/wycats) and contributors
