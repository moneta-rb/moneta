describe 'adapter_cassandra_with_default_expires' do
  let(:t_res){ 0.1 }
  let(:min_ttl){ t_res }

  moneta_build do
    Moneta::Adapters::Cassandra.new(keyspace: 'adapter_cassandra_with_default_expires', expires: min_ttl)
  end

  moneta_specs ADAPTER_SPECS.without_increment.without_create.with_native_expires.with_default_expires
end
