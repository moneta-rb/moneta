describe 'adapter_memcached_native', isolate: true, unstable: defined?(JRUBY_VERSION), retry: 3 do
  # See https://github.com/memcached/memcached/issues/307
  let(:t_res) { 1 }
  let(:min_ttl) { 2 }

  start_memcached 11214

  moneta_build do
    Moneta::Adapters::MemcachedNative.new(server: "127.0.0.1:11214")
  end

  moneta_specs ADAPTER_SPECS.with_native_expires
end
