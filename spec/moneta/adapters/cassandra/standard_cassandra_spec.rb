describe "standard_cassandra", retry: 3, adapter: :Cassandra do
  let(:t_res) { 1 }
  let(:min_ttl) { t_res }

  moneta_store :Cassandra, keyspace: "standard_cassandra"

  moneta_specs STANDARD_SPECS.without_increment.without_create.with_native_expires
end
