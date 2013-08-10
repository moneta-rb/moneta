require 'cql'

module Moneta
  module Adapters
    # Cassandra Cql backend
    # @api public
    class Cql
      include Defaults
      include ExpiresSupport

      attr_reader :backend

      # @param [Hash] options
      # @option options [String] :keyspace ('moneta') Cql keyspace
      # @option options [String] :table ('moneta') Cql column family
      # @option options [String] :host ('127.0.0.1') Server host name
      # @option options [Integer] :port (9160) Server port
      # @option options [Integer] :expires Default expiration time
      # @option options [::Cql::Client] :backend Use existing backend instance
      def initialize(options = {})
        self.default_expires = options[:expires]
        table = (options[:table] || 'moneta').to_sym
        if options[:backend]
          @backend = options[:backend]
        else
          keyspace = options[:keyspace] || 'moneta'

          @backend = Cql::Client.connect(:host => options[:host], :port => options[:port])

          # unless @backend.keyspaces.include?(keyspace)
          #   cf_def = ::Cql::ColumnFamily.new(:keyspace => keyspace, :name => @table.to_s)
          #   ks_def = ::Cql::Keyspace.new(:name => keyspace,
          #                                      :strategy_class => 'SimpleStrategy',
          #                                      :strategy_options => { 'replication_factor' => '1' },
          #                                      :replication_factor => 1,
          #                                      :cf_defs => [cf_def])
          #   # Wait for keyspace to be created (issue #24)
          #   10.times do
          #     begin
          #       @backend.add_keyspace(ks_def)
          #     rescue Exception => ex
          #       warn "Moneta::Adapters::Cql - #{ex.message}"
          #     end
          #     break if @backend.keyspaces.include?(keyspace)
          #     sleep 0.1
          #   end
          # end

          @backend.use(keyspace)
        end

        @create = @backend.prepare('INSERT INTO #{table} (key, value) VALUES (?, ?)')
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        if @backend.exists?(@table, key)
          load(key, options) if options.include?(:expires)
          true
        else
          false
        end
      end

      # (see Proxy#load)
      def load(key, options = {})
        if value = @backend.get(@table, key)
          expires = expires_value(options, nil)
          @backend.insert(@table, key, {'value' => value['value'] }, :ttl => expires || nil) if expires != nil
          value['value']
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @backend.insert(@table, key, {'value' => value}, :ttl => expires_value(options) || nil)
        value
      rescue
        # FIXME: We get spurious cql transport exceptions
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        if value = load(key, options)
          @backend.remove(@table, key)
          value
        end
      end

      # (see Proxy#clear)
      def clear(options = {})
        @backend.each_key(@table) do |key|
          delete(key)
        end
        self
      end

      # (see Proxy#close)
      def close
        @backend.disconnect!
        nil
      end
    end
  end
end
