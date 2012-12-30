# Copyright: 2011 TMX Credit
# Author: Potapov Sergey (aka Blake)

require 'cassandra'

module Moneta
  module Adapters
    # Cassandra backend
    # @api public
    class Cassandra
      include Defaults
      include ExpiresSupport

      # @param [Hash] options
      # @option options [String] :keyspace ('moneta') Cassandra keyspace
      # @option options [String] :column_family ('moneta') Cassandra column family
      # @option options [String] :host ('127.0.0.1') Server host name
      # @option options [Integer] :port (9160) Server port
      # @option options [Integer] :expires Default expiration time
      def initialize(options = {})
        options[:host] ||= '127.0.0.1'
        options[:port] ||=  9160
        self.default_expires = options[:expires]
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
              warn "Cassandra: #{ex.message}"
            end
            break if @client.keyspaces.include?(keyspace)
            sleep 0.1
          end
        end
        @client.keyspace = keyspace
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        if @client.exists?(@cf, key)
          load(key, options) if options.include?(:expires)
          true
        else
          false
        end
      end

      # (see Proxy#load)
      def load(key, options = {})
        value = @client.get(@cf, key)
        if value
          expires = expires_value(options, nil)
          @client.insert(@cf, key, {'value' => value['value'] }, :ttl => expires || nil) if expires != nil
          value['value']
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @client.insert(@cf, key, {'value' => value}, :ttl => expires_value(options) || nil)
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        if value = load(key, options)
          @client.remove(@cf, key)
          value
        end
      end

      # (see Proxy#clear)
      def clear(options = {})
        @client.each_key(@cf) do |key|
          delete(key)
        end
        self
      end
    end
  end
end
