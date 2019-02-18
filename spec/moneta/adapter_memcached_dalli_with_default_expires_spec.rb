describe 'adapter_memcached_dalli_with_default_expires', isolate: true, retry: 3 do
  # See https://github.com/memcached/memcached/issues/307
  let(:t_res) { 1 }
  let(:min_ttl) { 2 }

  start_memcached 11221

  moneta_build do
    Moneta::Adapters::MemcachedDalli.new(server: '127.0.0.1:11221', expires: min_ttl)
  end

  moneta_specs ADAPTER_SPECS.with_native_expires.with_default_expires
end
