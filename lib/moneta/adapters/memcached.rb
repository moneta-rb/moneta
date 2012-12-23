module Moneta
  module Adapters
    begin
      require 'moneta/adapters/memcached/native'
      Memcached = MemcachedNative
    rescue LoadError
      require 'moneta/adapters/memcached/dalli'
      Memcached = MemcachedDalli
    end
  end
end
