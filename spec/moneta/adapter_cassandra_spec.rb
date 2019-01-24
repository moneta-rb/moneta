describe 'adapter_cassandra', isolate: true, unstable: true do
  let(:t_res) { 0.125 }
  let(:min_ttl) { t_res }

  moneta_build do
    Moneta::Adapters::Cassandra.new(keyspace: 'adapter_cassandra')
  end

  moneta_specs ADAPTER_SPECS.without_increment.without_create.with_native_expires
end
