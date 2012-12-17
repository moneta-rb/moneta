# Copyright: 2011 TMX Credit
# Author: Potapov Sergey (aka Blake)

require 'cassandra'

module Juno
  module Adapters
    # Cassandra backend
    # @api public
    class Cassandra < Base
      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :keyspace - Cassandra keyspace (default 'juno')
      # * :column_family - Cassandra column family (default 'juno')
      # * :host - Server host name (default 127.0.0.1)
      # * :port - Server port (default 9160)
      def initialize(options = {})
        options[:keyspace] ||= 'juno'
        options[:host]     ||= '127.0.0.1'
        options[:port]     ||=  9160
        @cf = (options[:column_family] || 'juno').to_sym
        @client = ::Cassandra.new('system', "#{options[:host]}:#{options[:port]}")
        unless @client.keyspaces.include?(options[:keyspace])
          cf_def = ::Cassandra::ColumnFamily.new(:keyspace => options[:keyspace], :name => @cf.to_s)
          ks_def = ::Cassandra::Keyspace.new(:name => options[:keyspace],
                                             :strategy_class => 'org.apache.cassandra.locator.SimpleStrategy',
                                             :replication_factor => 1,
                                             :cf_defs => [cf_def])
          @client.add_keyspace(ks_def)
        end
        @client.keyspace = options[:keyspace]
      end

      def key?(key, options = {})
        @client.exists?(@cf, key)
      end

      def load(key, options = {})
        value = @client.get(@cf, key)
        if value
          if options.include?(:expires)
            store(key, value['value'], options)
          else
            value['value']
          end
        end
      end

      def delete(key, options = {})
        if value = load(key, options)
          @client.remove(@cf, key)
          value
        end
      end

      def store(key, value, options = {})
        @client.insert(@cf, key, {'value' => value}, :ttl => options[:expires])
        value
      end

      def clear(options = {})
        @client.each_key(@cf) do |key|
          delete(key)
        end
        self
      end
    end
  end
end
