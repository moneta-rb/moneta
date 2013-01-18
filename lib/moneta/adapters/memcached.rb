module Moneta
  module Adapters
    # Prefer Dalli over native Memcached!
    #
    # I measure no performance gain over the Dalli backend
    # using the Moneta backends.
    begin
      require 'moneta/adapters/memcached/dalli'
      Memcached = MemcachedDalli
    rescue LoadError
      require 'moneta/adapters/memcached/native'
      Memcached = MemcachedNative
    end
  end
end
