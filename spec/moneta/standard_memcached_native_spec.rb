describe 'standard_memcached_native' do
  moneta_store :MemcachedNative, {namespace: "simple_memcached_native"}
  moneta_specs STANDARD_SPECS.with_native_expires
end
