source 'https://rubygems.org'
gemspec

group :transformers, optional: true do
  group :tnet, optional: true do
    gem 'tnetstring'
  end

  group :bencode, optional: true do
    gem 'bencode'
  end

  group :ox, optional: true do
    gem 'ox', platforms: :ruby
  end

  group :bert, optional: true do
    gem 'bert', platforms: :ruby
  end

  group :php, optional: true do
    gem 'php-serialize'
  end

  group :bson, optional: true do
    gem 'bson', '>= 4.0.0'
  end

  group :msgpack, optional: true do
    gem 'msgpack', platforms: :ruby
    gem 'msgpack-jruby', platforms: :jruby
  end

  # Compressors used by Transformer
  group :bzip2, optional: true do
    gem 'rbzip2', '>= 0.3.0'
  end

  group :lz4, optional: true do
    gem 'lz4-ruby', platforms: :ruby
  end

  group :lzma, optional: true do
    gem 'ruby-lzma', platforms: :ruby
  end

  group :lzo, optional: true do
    gem 'lzoruby', platforms: :ruby
  end

  group :snappy, optional: true do
    gem 'snappy', platforms: :ruby
  end

  # Hash transformer library
  group :city, optional: true do
    gem 'cityhash', platforms: :ruby
  end
end

# Backends
group :Daybreak, optional: true do
  gem 'daybreak'
end

group :ActiveRecord, optional: true do
  gem 'activerecord', '~> 5.2'
end

group :Redis, optional: true do
  gem 'redis', '~> 4.2'
end

group :Mongo, optional: true do
  gem 'mongo', '>= 2'
end

group :Sequel, optional: true do
  gem 'sequel', '5.52.0'
end

group :Memcached, optional: true do
  group :MemcachedDalli, optional: true do
    gem 'dalli', '~> 2.7.11'
  end

  group :MemcachedNative, optional: true do
    gem 'jruby-memcached', platforms: :jruby
    gem 'memcached', platforms: :ruby
  end
end

group :Riak, optional: true do
  gem 'riak-client'
end

group :Cassandra, optional: true do
  install_if lambda { RUBY_ENGINE != 'ruby' || Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.0.0') } do
    gem 'cassandra-driver'
  end
end

group :TokyoTyrant, optional: true do
  gem 'tokyotyrant'
end

group :HBase, optional: true do
  gem 'hbaserb'
end

group :LocalMemCache, optional: true do
  gem 'localmemcache', platforms: :ruby
end

group :TDB, optional: true do
  gem 'tdb', platforms: :ruby
end

group :LevelDB, optional: true do
  gem 'leveldb-ruby', platforms: :ruby
end

group :LMDB, optional: true do
  gem 'lmdb', platforms: :mri
end

group :TokyoCabinet, optional: true do
  gem 'tokyocabinet', platforms: :ruby
end

group :KyotoCabinet, optional: true do
  install_if lambda { Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.7.0') } do
    gem 'kyotocabinet-ruby-reanimated', platforms: :ruby
  end
end

group :H2, optional: true do
  gem 'activerecord-jdbch2-adapter', platforms: :jruby, github: 'jruby/activerecord-jdbc-adapter', glob: 'activerecord-jdbch2-adapter/*.gemspec', branch: '52-stable'
end

group :GDBM, optional: true do
  gem 'ffi-gdbm', platforms: :jruby
end

group :RestClient do
  gem 'faraday'
  gem 'webrick'
end

group :DataMapper, optional: true do
  install_if lambda { RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.0.0') } do
    gem 'dm-core'
    gem 'dm-migrations'
    gem 'dm-mysql-adapter'
  end
end

group :Fog, optional: true do
  gem 'fog-aws', '>= 1.11.1'
  gem 'mime-types'
end

group :mysql, optional: true do
  gem 'activerecord-jdbcmysql-adapter', platforms: :jruby
  gem 'mysql2', platforms: :ruby
end

group :sqlite, optional: true do
  gem 'activerecord-jdbcsqlite3-adapter', platforms: :jruby
  gem 'sqlite3', '~> 1.5.3', platforms: :ruby
end

group :postgresql, optional: true do
  gem 'activerecord-jdbcpostgresql-adapter', platforms: :jruby
  gem 'pg', platforms: :ruby
end

group :SDBM, optional: true do
  install_if lambda { Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.0.0') } do
    gem 'sdbm', platforms: :ruby
  end
end

# Rack integration testing
group :rack do
  gem 'rack'
  gem 'rack-cache'
end

# Rails integration testing
group :rails do
  gem 'actionpack', '~> 5.2.0'
  gem 'minitest', '~> 5.0'
end

# Used for generating the feature matrix
group :doc, optional: true do
  gem 'kramdown', '~> 2.3.0'
  gem 'yard', '~> 0.9.20'
end

# Used for running a dev console
group :console, optional: true do
  gem 'irb'
  gem 'rdoc'
end
