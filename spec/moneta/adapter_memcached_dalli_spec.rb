describe 'adapter_memcached_dalli' do
  moneta_build do
    Moneta::Adapters::MemcachedDalli.new(namespace: "adapter_memcached_dalli")
  end

  moneta_specs ADAPTER_SPECS.with_native_expires
end
