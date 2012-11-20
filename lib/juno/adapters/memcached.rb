module Juno
  module Adapters
    begin
      require 'juno/adapters/memcached_native'
      Memcached = MemcachedNative
    rescue LoadError
      require 'juno/adapters/memcached_dalli'
      Memcached = MemcachedDalli
    end
  end
end
