source :rubygems
gemspec

# Testing
gem 'rake'
gem 'rspec'
gem 'parallel_tests'

# Serializer
#gem 'tnetstring'
gem 'bson'
gem 'multi_json'
gem 'json' # Ripple/Riak needs json

# Backends
gem 'dm-core'
gem 'dm-migrations'
gem 'dm-sqlite-adapter'
gem 'fog'
gem 'activerecord'
gem 'redis'
gem 'mongo'
gem 'couchrest'
gem 'sequel'
gem 'dalli'
gem 'riak-client'
gem 'hashery'

if defined?(JRUBY_VERSION)
  gem 'jdbc-sqlite3'
  gem 'activerecord-jdbc-adapter'
  gem 'activerecord-jdbcsqlite3-adapter'
else
  gem 'msgpack'
  gem 'tokyocabinet'
  gem 'memcached'
  gem 'sqlite3'
  gem 'ox'
end

#gem 'cassandra'
#gem 'localmemcache'
