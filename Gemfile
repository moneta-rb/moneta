# Rails 4 requires Ruby >= 1.9
def rails_version
  v = ['>= 3.2.11']
  v << '< 4.0.0' unless RUBY_VERSION >= '1.9'
  v
end

source 'https://rubygems.org'
gemspec

# Testing
gem 'rspec'
gem 'rspec-retry'

# Serializer used by Transformer
gem 'tnetstring'
gem 'bencode'
gem 'multi_json'
gem 'bson_ext', :platforms => :ruby
gem 'bson', :platforms => :jruby
gem 'ox', :platforms => :ruby
gem 'msgpack', :platforms => :ruby
gem 'msgpack-jruby', :platforms => :jruby
gem 'bert', :platforms => :ruby
gem 'php_serialize'

# Compressors used by Transformer
if RUBY_VERSION < '2.0'
  gem 'bzip2-ruby', :platforms => :mri # Only on mri currently
end
gem 'lz4-ruby', :platforms => :ruby
gem 'ruby-lzma', :platforms => :ruby
gem 'lzoruby', :platforms => :ruby
gem 'snappy', :platforms => :ruby
gem 'qlzruby', :platforms => :ruby

# Hash transformer library
gem 'cityhash', :platforms => :ruby

# Backends
gem 'faraday'
gem 'daybreak'
gem 'dm-core'
gem 'dm-migrations'
gem 'dm-mysql-adapter'
# FIXME: Use fog master because of failing tests, fixed after 1.11.1
gem 'fog', :github => 'fog/fog'
gem 'activerecord', *rails_version
gem 'redis'
gem 'mongo'
gem 'sequel'
gem 'dalli'
gem 'riak-client'
gem 'cassandra'
gem 'tokyotyrant'
#gem 'ruby-tokyotyrant', :platforms => :ruby
#gem 'hbaserb'
#gem 'localmemcache'
gem 'tdb', :platforms => :ruby
gem 'leveldb-ruby', :platforms => :ruby
if RUBY_VERSION >= '1.9'
  gem 'lmdb', :platforms => :mri
end
if RUBY_VERSION < '2.0'
  gem 'tokyocabinet', :platforms => :ruby
end
#if RUBY_VERSION < '2.0' && !defined?(JRUBY_VERSION)
  # FIXME: We have to check manually for jruby
  # otherwise bundle install --deployment doesn't work
#  gem 'kyotocabinet-ruby', :github => 'minad/kyotocabinet-ruby'
#end
gem 'memcached', :platforms => :ruby
gem 'jruby-memcached', :platforms => :jruby
gem 'sqlite3', :platforms => :ruby
gem 'activerecord-jdbc-adapter', :platforms => :jruby
gem 'activerecord-jdbcmysql-adapter', :platforms => :jruby
gem 'mysql2', '>= 0.3.12b5', :platforms => :ruby
# gdbm for jruby needs ffi
gem 'ffi', :platforms => :jruby
gem 'gdbm', :platforms => :jruby

# Rack integration testing
gem 'rack'
gem 'rack-cache'

# Rails integration testing
gem 'actionpack', *rails_version
gem 'minitest', '~> 4.7.4'

# Fix versions for old ruby 1.8
if RUBY_VERSION < '1.9'
  gem 'nokogiri', '< 1.6'
end
