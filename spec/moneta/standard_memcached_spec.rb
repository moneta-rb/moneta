describe 'standard_memcached', retry: 3 do
  let(:t_res) { 1 }
  let(:min_ttl) { 2 }

  start_memcached 11220

  moneta_store :Memcached, server: "127.0.0.1:11220"
  moneta_specs STANDARD_SPECS.with_native_expires
end
