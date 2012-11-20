source :rubygems
gemspec

# Testing
gem 'rake'
gem 'rspec'
gem 'parallel_tests'

# Serializer
#gem 'tnetstring'
gem 'msgpack'
gem 'bson'
gem 'multi_json'
gem 'json' # Ripple/Riak needs json

# Backends
gem 'datamapper'
gem 'dm-sqlite-adapter'
gem 'fog'
gem 'activerecord'
gem 'redis'
gem 'mongo'
gem 'couchrest'
gem 'sequel'
gem 'dalli'
gem 'riak-client'

if defined?(JRUBY_VERSION)
  gem 'jdbc-sqlite3'
  gem 'activerecord-jdbc-adapter'
  gem 'activerecord-jdbcsqlite3-adapter'
else
  gem 'tokyocabinet'
  gem 'memcached'
  gem 'sqlite3'
end

#gem 'cassandra'
#gem 'localmemcache'
