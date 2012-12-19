# Copyright: 2011 TMX Credit
# Author: Potapov Sergey (aka Blake)

require 'cassandra'

module Moneta
  module Adapters
    # Cassandra backend
    # @api public
    class Cassandra < Base
      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :keyspace - Cassandra keyspace (default 'moneta')
      # * :column_family - Cassandra column family (default 'moneta')
      # * :host - Server host name (default 127.0.0.1)
      # * :port - Server port (default 9160)
      def initialize(options = {})
        options[:host] ||= '127.0.0.1'
        options[:port] ||=  9160
        keyspace = (options[:keyspace] ||= 'moneta')
        @cf = (options[:column_family] || 'moneta').to_sym
        @client = ::Cassandra.new('system', "#{options[:host]}:#{options[:port]}")
        unless @client.keyspaces.include?(keyspace)
          cf_def = ::Cassandra::ColumnFamily.new(:keyspace => keyspace, :name => @cf.to_s)
          ks_def = ::Cassandra::Keyspace.new(:name => keyspace,
                                             :strategy_class => 'SimpleStrategy',
                                             :strategy_options => { 'replication_factor' => '1' },
                                             :replication_factor => 1,
                                             :cf_defs => [cf_def])
          # Wait for keyspace to be created (issue #24)
          10.times do
            begin
              @client.add_keyspace(ks_def)
            rescue Exception => ex
              puts "Cassandra: #{ex.message}"
            end
            break if @client.keyspaces.include?(keyspace)
            sleep 0.1
          end
        end
        @client.keyspace = keyspace
      end

      def key?(key, options = {})
        if @client.exists?(@cf, key)
          if options.include?(:expires) && (value = load(key))
            store(key, value, options)
          end
          true
        else
          false
        end
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
