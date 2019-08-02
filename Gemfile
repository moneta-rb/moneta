source 'https://rubygems.org'
gemspec

# Used by multiple backends / transformers
gem 'multi_json', groups: %i{json couch cassandra}
gem 'faraday', groups: %i{couch restclient}
gem 'manticore', groups: %i{couch restclient}, platforms: :jruby

# Serializers used by Transformer
gem 'tnetstring', group: :tnet
gem 'bencode', group: :bencode
gem 'ox', platforms: :ruby, group: :ox
gem 'bert', platforms: :ruby, group: :bert
gem 'php-serialize', group: :php

group :bson do
  gem 'bson', '>= 2.0.0'
end

group :msgpack do
  gem 'msgpack', platforms: :ruby
  gem 'msgpack-jruby', platforms: :jruby
end

# Compressors used by Transformer
gem 'rbzip2', '~> 0.3.0', group: :bzip2
gem 'lz4-ruby', platforms: :ruby, group: :lz4
gem 'ruby-lzma', platforms: :ruby, group: :lzma
gem 'lzoruby', platforms: :ruby, group: :lzo
gem 'snappy', platforms: :ruby, group: :snappy
gem 'qlzruby', platforms: :ruby, group: :quicklz

# Hash transformer library
gem 'cityhash', platforms: :ruby, group: :city

# Backends
gem 'daybreak', group: :daybreak
gem 'activerecord', '~> 5.2', group: :activerecord
gem 'redis', '~> 4.0.0', group: :redis
gem 'mongo', '~> 2.1.0', group: :mongo_official
gem 'moped', '>= 2.0.0', group: :mongo_moped
gem 'sequel', group: :sequel
gem 'dalli', group: :memcached_dalli
gem 'riak-client', group: :riak
gem 'cassandra-driver', group: :cassandra
gem 'tokyotyrant', group: :tokyotyrant
gem 'hbaserb', group: :hbase
gem 'localmemcache', platforms: :ruby, group: :localmemcache
gem 'tdb', platforms: :ruby, group: :tdb
gem 'leveldb-ruby', platforms: :ruby, group: :leveldb
gem 'lmdb', platforms: :mri, group: :lmdb
gem 'tokyocabinet', platforms: :ruby, group: :tokyocabinet
gem 'kyotocabinet-ruby-reanimated', platforms: :ruby, group: :kyotocabinet
gem 'memcached', platforms: :ruby, group: :memcached_native
gem 'jruby-memcached', platforms: :jruby, group: :memcached_native
gem 'activerecord-jdbch2-adapter', platforms: :jruby, group: :h2, github: 'jruby/activerecord-jdbc-adapter', glob: 'activerecord-jdbch2-adapter/*.gemspec', branch: '52-stable'
gem 'ffi-gdbm', platforms: :jruby, group: :gdbm
group :restclient do
  gem 'fishwife', platforms: :jruby
  gem 'rjack-logback', platforms: :jruby
end

group :datamapper do
  gem 'dm-core'
  gem 'dm-migrations'
  gem 'dm-mysql-adapter'
end

group :fog do
  gem 'fog-aws', '>= 1.11.1'
  gem 'mime-types'
end

group :mysql do
  gem 'activerecord-jdbcmysql-adapter', platforms: :jruby
  gem 'mysql2', platforms: :ruby
end

group :sqlite do
  gem 'activerecord-jdbcsqlite3-adapter', platforms: :jruby
  gem 'sqlite3', '~> 1.3.6', platforms: :ruby
end

group :postgresql do
  gem 'activerecord-jdbcpostgresql-adapter', platforms: :jruby
  gem 'pg', platforms: :ruby
end

# Rack integration testing
group :rack do
  gem 'rack'
  gem 'rack-cache'
end

# Rails integration testing
group :rails do
  gem 'actionpack', '~> 5.0'
  gem 'minitest', '~> 5.0'
end

# Used for generating the feature matrix
group :doc, optional: true do
  gem 'kramdown', '~> 1.17.0'
  gem 'yard', '~> 0.9.20'
end
