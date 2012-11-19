Juno: A unified interface for key/value stores
================================================

[![Build Status](https://secure.travis-ci.org/minad/juno.png?branch=master)](http://travis-ci.org/minad/juno) [![Dependency Status](https://gemnasium.com/minad/juno.png?travis)](https://gemnasium.com/minad/juno) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/minad/juno)

Juno provides a standard interface for interacting with various kinds of key/value stores. Juno
is based on Moneta and replaces it with a mostly compatible interface. The reason for the
fork was that Moneta was unmaintained for a long time.

Out of the box, it supports:

* File Store
* Memcached store (memcached and dalli)
* In-memory store
* DataMapper
* BerkeleyDB (dbm)
* GDBM
* SDBM
* Redis
* Riak
* TokyoCabinet
* CouchDB
* MongoDB
* ActiveRecord
* YAML store
* PStore
* LocalMemCache
* Sequel
* Sqlite3
* Fog cloud storage (Amazon S3, Rackspace, ...)
* Cassandra

The Juno API is purposely extremely similar to the Hash API. In order so support an
identical API across stores, it does not support iteration or partial matches.

The API
=======

```
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
```

Proxy store & Expiry
====================

The memcached and redis backends supports expires values directly:

```ruby
cache = Juno::Memcached.new
# Expires in 10 seconds
cache.store(key, value, :expires => 10)
```

You can add the expires feature to other backends using the Expires proxy:

```ruby
cache = Juno::Expires.new(Juno::File.new(...))
cache.store(key, value, :expires => 10)
```

Authors
=======

* Moneta originally by wycats
* Juno by Daniel Mendler
