describe 'adapter_memcached_with_default_expires', isolate: true, retry: 3, adapter: :Memcached do
  # See https://github.com/memcached/memcached/issues/307
  let(:t_res) { 1 }
  let(:min_ttl) { 2 }

  start_memcached 11217

  moneta_build do
    Moneta::Adapters::Memcached.new(server: "127.0.0.1:11217", expires: min_ttl)
  end

  moneta_specs ADAPTER_SPECS.with_native_expires.with_default_expires
end
