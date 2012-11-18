module Juno
  begin
    Memcached = MemcachedNative
  rescue LoadError
    Memcached = MemcachedDalli
  end
end
