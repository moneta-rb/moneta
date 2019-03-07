# This is used in order to speed up cassandra specs
RSpec.shared_context :global_cassandra_cluster do
  before :all do
    require 'cassandra'
    $moneta_cassandra_cluster ||= ::Cassandra.cluster
  end

  let(:cluster) { $moneta_cassandra_cluster }
end

RSpec.configure do |config|
  config.after :suite do
    if $moneta_cassandra_cluster
      $moneta_cassandra_cluster.close
      $moneta_cassandra_cluster = nil
    end
  end
end
