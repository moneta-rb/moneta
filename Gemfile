source :rubygems
gemspec

def alternatives(gems)
  if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
    [gems[:rbx]].flatten.compact.each {|g| gem g }
  elsif defined?(JRUBY_VERSION)
    [gems[:jruby]].flatten.compact.each {|g| gem g }
  else
    [gems[:mri]].flatten.compact.each {|g| gem g }
  end
end

# Testing
gem 'rake'
gem 'rspec'

# Serializer used by Transformer
gem 'tnetstring'
gem 'bencode'
gem 'multi_json'
alternatives :mri => 'bson_ext', :rbx => 'bson_ext', :jruby => 'bson'
alternatives :mri => 'ox', :rbx => 'ox'
alternatives :mri => 'msgpack', :rbx => 'msgpack', :jruby => 'msgpack-jruby'
alternatives :mri => 'bert', :rbx => 'bert'

# Compressors used by Transformer
alternatives :mri => 'bzip2-ruby'
alternatives :mri => 'ruby-lzma', :rbx => 'ruby-lzma'
alternatives :mri => 'lzoruby', :rbx => 'lzoruby'
alternatives :mri => 'snappy', :rbx => 'snappy'
alternatives :mri => 'qlzruby', :rbx => 'qlzruby'

# Backends
gem 'daybreak'
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
gem 'cassandra'
#gem 'hbaserb'
#gem 'localmemcache'
alternatives :mri => 'tdb', :rbx => 'tdb'
alternatives :mri => 'leveldb-ruby', :rbx => 'leveldb-ruby'
alternatives :mri => 'tokyocabinet', :rbx => 'tokyocabinet'
alternatives :mri => 'memcached', :rbx => 'memcached', :jruby => 'jruby-memcached'
alternatives :mri => 'sqlite3', :rbx => 'sqlite3', :jruby => %w(jdbc-sqlite3 activerecord-jdbc-adapter activerecord-jdbcsqlite3-adapter)
alternatives :jruby => %w(ffi gdbm) # gdbm for jruby needs ffi

# Rack integration testing
gem 'rack'
gem 'rack-cache'

# Rails integration testing
gem 'actionpack'
gem 'minitest'
