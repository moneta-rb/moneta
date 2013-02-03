source :rubygems
gemspec

# Testing
gem 'rake'
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

# Compressors used by Transformer
gem 'bzip2-ruby', :platforms => :mri # Only on mri currently
gem 'ruby-lzma', :platforms => :ruby
gem 'lzoruby', :platforms => :ruby
gem 'snappy', :platforms => :ruby
gem 'qlzruby', :platforms => :ruby

# Backends
gem 'daybreak'
gem 'dm-core'
gem 'dm-migrations'
gem 'dm-sqlite-adapter'
gem 'fog'
gem 'activerecord', '>= 3.2.9'
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
gem 'tokyocabinet', :platforms => :ruby
unless defined?(JRUBY_VERSION)
  # FIXME: We have to check manually for jruby
  # otherwise bundle install --deployment doesn't work
  gem 'kyotocabinet-ruby', :github => 'minad/kyotocabinet-ruby'
end
gem 'memcached', :platforms => :ruby
gem 'jruby-memcached', :platforms => :jruby
gem 'sqlite3', :platforms => :ruby
gem 'jdbc-sqlite3', :platforms => :jruby
gem 'activerecord-jdbc-adapter', :platforms => :jruby
gem 'activerecord-jdbcsqlite3-adapter', :platforms => :jruby
# gdbm for jruby needs ffi
gem 'ffi', :platforms => :jruby
gem 'gdbm', :platforms => :jruby

# Rack integration testing
gem 'rack'
gem 'rack-cache'

# Rails integration testing
gem 'actionpack'
gem 'minitest'
