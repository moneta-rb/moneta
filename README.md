Juno: A unified interface for key/value stores
================================================

[![Build Status](https://secure.travis-ci.org/minad/juno.png?branch=master)](http://travis-ci.org/minad/juno) [![Dependency Status](https://gemnasium.com/minad/juno.png?travis)](https://gemnasium.com/minad/juno) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/minad/juno)

Juno provides a standard interface for interacting with various kinds of key/value stores. Juno
is based on Moneta and replaces it with a mostly compatible interface. The reason for the
fork was that Moneta was unmaintained for a long time.

Out of the box, it supports:

* Memory:
    * In-memory store (Juno::Memory)
    * LocalMemCache (Juno::LocalMemCache)
    * Memcached store (Juno::Memcached, Juno::MemcachedNative and Juno::MemcachedDalli)
* Relational Databases:
    * DataMapper (Juno::DataMapper)
    * ActiveRecord (Juno::ActiveRecord)
    * Sequel (Juno::Sequel)
    * Sqlite3 (Juno::Sqlite)
* Filesystem:
    * PStore (Juno::PStore)
    * YAML store (Juno::YAML)
    * Filesystem directory store (Juno::File)
    * Filesystem directory store which spreads files in subdirectories using md5 hash (Juno::HashFile)
* Key/value databases:
    * Berkeley DB (Juno::DBM)
    * GDBM (Juno::GDBM)
    * SDBM (Juno::SDBM)
    * Redis (Juno::Redis)
    * Riak (Juno::Riak)
    * TokyoCabinet (Juno::TokyoCabinet)
    * Cassandra (Juno::Cassandra)
* Document databases:
    * CouchDB (Juno::Couch)
    * MongoDB (Juno::MongoDB)
* Cloud storage
    * Fog cloud storage which supports Amazon S3, Rackspace, etc. (Juno::Fog)

The Juno API is purposely extremely similar to the Hash API. In order so support an
identical API across stores, it does not support iteration or partial matches.

Links
-----

* Source: <http://github.com/minad/juno>
* Bugs:   <http://github.com/minad/juno/issues>
* API documentation:
    * Latest Gem: <http://rubydoc.info/gems/juno/frames>
    * GitHub master: <http://rubydoc.info/github/minad/juno/master/frames>

The API
-------

~~~
#initialize(options)              options differs per-store, and is used to set up the store

#[](key)                          retrieve a key. if the key is not available, return nil

#load(key, options = {})          retrieve a key. if the key is not available, return nil

#fetch(key, options = {}, &block) retrieve a key. if the key is not available, execute the
                                  block and return its return value.

#fetch(key, value, options = {})  retrieve a key. if the key is not available, return the value

#[]=(key, value)                  set a value for a key. if the key is already used, clobber it.
                                  keys set using []= will never expire

#delete(key, options = {})        delete the key from the store and return the current value

#key?(key, options = {})          true if the key exists, false if it does not

#store(key, value, options = {})  same as []=, but you can supply options

#clear(options = {})              clear all keys in this store

#close                            close database connection
~~~

Proxy store and Expiration
------------------------

The memcached and redis backends supports expires values directly:

~~~ ruby
cache = Juno::Memcached.new
# Expires in 10 seconds
cache.store(key, value, :expires => 10)
~~~

You can add the expires feature to other backends using the Expires proxy:

~~~ ruby
cache = Juno::Expires.new(Juno::File.new(...))
cache.store(key, value, :expires => 10)
~~~

Authors
-------

* Moneta originally by wycats
* Juno by Daniel Mendler
