source :rubygems
gemspec

def alternatives(gems)
  if defined?(JRUBY_VERSION)
    [gems[:jruby]].flatten.compact.each {|g| gem g }
  else
    [gems[:mri]].flatten.compact.each {|g| gem g }
  end
end

# Testing
gem 'rake'
gem 'rspec'
gem 'parallel_tests'

# Serializer used by Transformer
gem 'tnetstring'
gem 'bencode'
gem 'multi_json'
alternatives :mri => 'bson_ext', :jruby => 'bson'
alternatives :mri => 'ox'
alternatives :mri => 'msgpack', :jruby => 'msgpack-jruby'
alternatives :mri => 'bert'

# Compressors used by Transformer
alternatives :mri => 'bzip2-ruby'
alternatives :mri => 'ruby-lzma'
alternatives :mri => 'qlzruby'
alternatives :mri => 'lzoruby'
alternatives :mri => 'snappy'

# Backends
gem 'dm-core'
gem 'dm-migrations'
gem 'dm-sqlite-adapter'
gem 'fog'
gem 'activerecord', '>= 3.2.9'
gem 'redis'
gem 'mongo'
gem 'couchrest'
gem 'sequel'
gem 'dalli'
gem 'riak-client'
gem 'hashery'
gem 'cassandra'
#gem 'localmemcache'
alternatives :mri => 'leveldb-ruby'
alternatives :mri => 'tokyocabinet'
alternatives :mri => 'memcached', :jruby => 'jruby-memcached'
alternatives :mri => 'sqlite3', :jruby => %w(jdbc-sqlite3 activerecord-jdbc-adapter activerecord-jdbcsqlite3-adapter)
alternatives :jruby => %w(ffi gdbm) # gdbm for jruby needs ffi

# Integration
gem 'rack'
gem 'rack-cache'
