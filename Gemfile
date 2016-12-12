source 'https://rubygems.org'
gemspec

# Testing
gem 'rspec', '~> 2.0'
gem 'rspec-retry', '0.4.4' # 0.4.5 does not work with rspec 2

# Serializer used by Transformer
gem 'tnetstring'
gem 'bencode'
gem 'multi_json'
gem 'bson_ext', platforms: :ruby
gem 'bson', '>= 2.0.0'
gem 'ox', platforms: :ruby
gem 'msgpack', platforms: :ruby
gem 'msgpack-jruby', platforms: :jruby
gem 'bert', platforms: :ruby
gem 'php_serialize'

# Compressors used by Transformer
gem 'rbzip2'
gem 'lz4-ruby', platforms: :ruby
gem 'ruby-lzma', platforms: :ruby
gem 'lzoruby', platforms: :ruby
gem 'snappy', platforms: :ruby
gem 'qlzruby', platforms: :ruby

# Hash transformer library
gem 'cityhash', platforms: :ruby

# Backends
gem 'faraday'
gem 'daybreak'
gem 'dm-core'
gem 'dm-migrations'
gem 'dm-mysql-adapter'
if RUBY_VERSION < '2.0'
  gem 'fog', '~> 1.12'
  gem 'mime-types', '~> 2.0'
  gem 'addressable', '~> 2.4.0'
else
  gem 'fog', '>= 1.11.1'
  gem 'mime-types'
end
gem 'activerecord', '~> 4.0.0'
gem 'redis'
gem 'mongo', '~> 2.1.0'
gem 'moped', '>= 2.0.0'
gem 'sequel'
gem 'dalli'
gem 'riak-client'
gem 'cassandra'
if RUBY_VERSION < '2.0'
  gem 'json', '~> 1.0'
end
gem 'tokyotyrant'
#gem 'ruby-tokyotyrant', platforms: :ruby
#gem 'hbaserb'
gem 'localmemcache'
gem 'tdb', platforms: :ruby
gem 'leveldb-ruby', platforms: :ruby
gem 'lmdb', platforms: :mri
if RUBY_VERSION < '2.0'
  gem 'tokyocabinet', platforms: :ruby
end
#if RUBY_VERSION < '2.0' && !defined?(JRUBY_VERSION)
  # FIXME: We have to check manually for jruby
  # otherwise bundle install --deployment doesn't work
#  gem 'kyotocabinet-ruby', github: 'minad/kyotocabinet-ruby'
#end
gem 'memcached', platforms: :ruby
gem 'jruby-memcached', platforms: :jruby
gem 'sqlite3', platforms: :ruby
gem 'activerecord-jdbc-adapter', platforms: :jruby
gem 'activerecord-jdbcmysql-adapter', platforms: :jruby
gem 'mysql2', '~> 0.3.12b5', platforms: :ruby
# gdbm for jruby needs ffi
gem 'ffi', platforms: :jruby
gem 'gdbm', platforms: :jruby

# Rack integration testing
gem 'rack'
gem 'rack-cache'

# Rails integration testing
gem 'actionpack', '~> 4.0.0'
gem 'minitest', '~> 4.7.4'
