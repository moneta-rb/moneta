require_relative './helper.rb'

describe 'adapter_cassandra_with_default_expires', isolate: true, retry: 3, adapter: :Cassandra, unsupported: RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.0.0') do
  let(:t_res) { 1 }
  let(:min_ttl) { 2 }

  include_context :global_cassandra_cluster

  moneta_build do
    Moneta::Adapters::Cassandra.new(
      cluster: cluster,
      keyspace: 'adapter_cassandra_with_default_expires',
      expires: min_ttl,
      create_keyspace: { durable_writes: false })
  end

  moneta_specs DEFAULT_EXPIRES_SPECS
end
