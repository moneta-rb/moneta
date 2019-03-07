require_relative './helper.rb'

describe "standard_cassandra", retry: 3, adapter: :Cassandra do
  let(:t_res) { 1 }
  let(:min_ttl) { t_res }

  include_context :global_cassandra_cluster

  moneta_store :Cassandra do
    {
      cluster: cluster,
      keyspace: "standard_cassandra",
      create_keyspace: { durable_writes: false }
    }
  end

  moneta_specs STANDARD_SPECS.without_increment.without_create.with_native_expires
end
