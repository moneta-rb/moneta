describe 'adapter_cassandra', retry: 3, adapter: :Cassandra do
  let(:t_res) { 1 }
  let(:min_ttl) { t_res }

  moneta_build do
    Moneta::Adapters::Cassandra.new(keyspace: 'adapter_cassandra')
  end

  moneta_specs ADAPTER_SPECS.without_increment.without_create.with_native_expires.with_values(:nil).with_each_key
end
