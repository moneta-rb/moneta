describe 'adapter_memcached_dalli_with_default_expires' do
  moneta_build do
    Moneta::Adapters::MemcachedDalli.new(expires: 1)
  end

  moneta_specs ADAPTER_SPECS.with_native_expires.with_default_expires
end
