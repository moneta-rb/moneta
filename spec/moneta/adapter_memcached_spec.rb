describe 'adapter_memcached', isolate: true do
  # See https://github.com/memcached/memcached/issues/307
  let(:t_res) { 1 }
  let(:min_ttl) { 2 }

  moneta_build do
    Moneta::Adapters::Memcached.new(namespace: "adapter_memcached")
  end

  moneta_specs ADAPTER_SPECS.with_native_expires
end
