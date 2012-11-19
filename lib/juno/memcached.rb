module Juno
  begin
    require 'juno/memcached_native'
    Memcached = MemcachedNative
  rescue LoadError
    require 'juno/memcached_dalli'
    Memcached = MemcachedDalli
  end
end
