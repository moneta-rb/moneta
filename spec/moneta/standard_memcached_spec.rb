describe 'standard_memcached' do
  moneta_store :Memcached, {namespace: "simple_memcached"}
  moneta_specs STANDARD_SPECS.with_native_expires
end
