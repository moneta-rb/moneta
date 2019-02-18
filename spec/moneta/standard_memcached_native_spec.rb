describe 'standard_memcached_native', unstable: defined?(JRUBY_VERSION), retry: 3 do
  let(:t_res) { 1 }
  let(:min_ttl) { 2 }

  start_memcached 11219

  moneta_store :MemcachedNative, server: "127.0.0.1:11219"
  moneta_specs STANDARD_SPECS.with_native_expires
end
