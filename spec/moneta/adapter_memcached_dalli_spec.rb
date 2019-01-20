describe 'adapter_memcached_dalli', isolate: true do
  # See https://github.com/memcached/memcached/issues/307
  let(:t_res){ 1 }
  let(:min_ttl){ 2 }

  moneta_build do
    Moneta::Adapters::MemcachedDalli.new(namespace: "adapter_memcached_dalli")
  end

  moneta_specs ADAPTER_SPECS.with_native_expires
end
