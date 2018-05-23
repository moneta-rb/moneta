describe 'standard_memcached' do
  let(:t_res){ 1 }
  let(:min_ttl){ 2 }

  moneta_store :Memcached, {namespace: "simple_memcached"}
  moneta_specs STANDARD_SPECS.with_native_expires
end
