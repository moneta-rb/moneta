describe 'adapter_memcached' do
  moneta_build do
    Moneta::Adapters::Memcached.new(namespace: "adapter_memcached")
  end

  moneta_specs ADAPTER_SPECS.with_native_expires
end
