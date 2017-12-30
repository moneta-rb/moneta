describe 'adapter_memcached_native' do
  moneta_build do
    Moneta::Adapters::MemcachedNative.new(namespace: "adapter_memcached_native")
  end

  moneta_specs ADAPTER_SPECS.with_native_expires
end
