describe 'standard_memcached_dalli' do
  moneta_store :MemcachedDalli, {namespace: "simple_memcached_dalli"}
  moneta_specs STANDARD_SPECS.with_native_expires
end
