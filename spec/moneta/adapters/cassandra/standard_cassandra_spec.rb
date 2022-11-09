require_relative './helper.rb'

describe "standard_cassandra", retry: 3, adapter: :Cassandra, unsupported: RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.0.0') do
  let(:t_res) { 1 }
  let(:min_ttl) { 2 }

  include_context :global_cassandra_cluster

  moneta_store :Cassandra do
    {
      cluster: cluster,
      keyspace: "standard_cassandra",
      create_keyspace: { durable_writes: false }
    }
  end

  moneta_specs STANDARD_SPECS.without_increment.without_create.with_native_expires.with_each_key
end
