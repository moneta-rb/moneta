module Moneta
  module Adapters
    begin
      require 'moneta/adapters/memcached_native'
      Memcached = MemcachedNative
    rescue LoadError
      require 'moneta/adapters/memcached_dalli'
      Memcached = MemcachedDalli
    end
  end
end
