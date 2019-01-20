describe 'standard_memcached_native', isolate: true do
  let(:t_res){ 1 }
  let(:min_ttl){ 2 }

  moneta_store :MemcachedNative, {namespace: "simple_memcached_native"}
  moneta_specs STANDARD_SPECS.with_native_expires
end
