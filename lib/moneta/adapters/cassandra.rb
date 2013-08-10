module Moneta
  module Adapters
    begin
      require 'moneta/adapters/cassandra/thrift'
      Cassandra = CassandraThrift
    rescue LoadError
      require 'moneta/adapters/cassandra/cql'
      Cassandra = CassandraCQL
    end
  end
end
