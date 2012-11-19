source :rubygems
gemspec

if RUBY_VERSION > '1.9'
  # HACK: CouchRest don't work currently on 1.8
 gem 'couchrest'
end

gem 'datamapper'
gem 'dm-sqlite-adapter'
gem 'fog'
gem 'activerecord'
gem 'redis'
gem 'mongo'
gem 'sequel'
gem 'dalli'
gem 'json' # Ripple/Riak needs json
gem 'ripple'

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
