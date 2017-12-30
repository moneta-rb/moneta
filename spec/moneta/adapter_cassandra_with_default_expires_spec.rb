describe 'adapter_cassandra_with_default_expires' do
  moneta_build do
    Moneta::Adapters::Cassandra.new(keyspace: 'adapter_cassandra_with_default_expires', expires: 1)
  end

  moneta_specs ADAPTER_SPECS.without_increment.without_create.with_native_expires.with_default_expires
end
