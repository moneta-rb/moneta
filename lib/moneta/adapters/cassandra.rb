require 'cassandra'

module Moneta
  module Adapters
    # Cassandra backend
    # @api public
    class Cassandra < Adapter
      include ExpiresSupport

      supports :each_key

      config :table, default: 'moneta'
      config :key_column, default: 'key'
      config :value_column, default: 'value'
      config :updated_column, default: 'updated_at'
      config :expired_column, default: 'expired'
      config :read_consistency, default: :all
      config :write_consistency, default: :all

      backend do |keyspace: 'moneta', cluster: nil, create_keyspace: nil, **options|
        cluster ||= ::Cassandra.cluster(options).tap do |own_cluster|
          @own_cluster = cluster
        end

        begin
          cluster.connect(keyspace)
        rescue ::Cassandra::Errors::InvalidError
          backend = cluster.connect
          create_keyspace(backend, keyspace, create_keyspace)
          backend.execute("USE " + keyspace)
          backend
        end
      end

      # @param [Hash] options
      # @option options [String] :keyspace ('moneta') Cassandra keyspace
      # @option options [String] :table ('moneta') Cassandra table
      # @option options [String] :host ('127.0.0.1') Server host name
      # @option options [Integer] :port (9160) Server port
      # @option options [Integer] :expires Default expiration time
      # @option options [String] :key_column ('key') Name of the key column
      # @option options [String] :value_column ('value') Name of the value
      #   column
      # @option options [String] :updated_column ('updated_at') Name of the
      #   column used to track last update
      # @option options [String] :expired_column ('expired') Name of the column
      #   used to track expiry
      # @option options [Symbol] :read_consistency (:all) Default read
      #   consistency
      # @option options [Symbol] :write_consistency (:all) Default write
      #   consistency
      # @option options [Proc, Boolean, Hash] :create_keyspace Provide a proc
      #   for creating the keyspace, or a Hash of options to use when creating
      #   it, or set to false to disable.  The Proc will only be called if the
      #   keyspace does not already exist.
      # @option options [::Cassandra::Cluster] :cluster Existing cluster to use
      # @option options [::Cassandra::Session] :backend Existing session to use
      # @option options Other options passed to `Cassandra#cluster`
      def initialize(options = {})
        super

        backend.execute <<-CQL
          CREATE TABLE IF NOT EXISTS #{config.table} (
            #{config.key_column} blob,
            #{config.value_column} blob,
            #{config.updated_column} timeuuid,
            #{config.expired_column} boolean,
            PRIMARY KEY (#{config.key_column}, #{config.updated_column})
          )
        CQL

        prepare_statements
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        rc, wc = consistency(options)
        if (expires = expires_value(options, nil)) != nil
          # Because Cassandra expires each value in a column, rather than the
          # whole column, when we want to update the expiry we load the value
          # and then re-set it in order to update the TTL.
          return false unless
            row = backend.execute(@load, options.merge(consistency: rc, arguments: [key])).first and
              row[config.expired_column] != nil
          backend.execute(@update_expires,
                          options.merge(consistency: wc,
                                        arguments: [(expires || 0).to_i,
                                                    timestamp,
                                                    row[config.value_column],
                                                    key,
                                                    row[config.updated_column]]))
          true
        elsif row = backend.execute(@key, options.merge(consistency: rc, arguments: [key])).first
          row[config.expired_column] != nil
        else
          false
        end
      end

      # (see Proxy#load)
      def load(key, options = {})
        rc, wc = consistency(options)
        if row = backend.execute(@load, options.merge(consistency: rc, arguments: [key])).first and row[config.expired_column] != nil
          if (expires = expires_value(options, nil)) != nil
            backend.execute(@update_expires,
                            options.merge(consistency: wc,
                                          arguments: [(expires || 0).to_i,
                                                      timestamp,
                                                      row[config.value_column],
                                                      key,
                                                      row[config.updated_column]]))
          end
          row[config.value_column]
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        _, wc = consistency(options)
        expires = expires_value(options)
        t = timestamp
        batch = backend.batch do |batch|
          batch.add(@store_delete, arguments: [t, key])
          batch.add(@store, arguments: [key, value, (expires || 0).to_i, t + 1])
        end
        backend.execute(batch, options.merge(consistency: wc))
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        rc, wc = consistency(options)
        result = backend.execute(@delete_value, options.merge(consistency: rc, arguments: [key]))
        if row = result.first and row[config.expired_column] != nil
          backend.execute(@delete, options.merge(consistency: wc, arguments: [timestamp, key, row[config.updated_column]]))
          row[config.value_column]
        end
      end

      # (see Proxy#clear)
      def clear(options = {})
        backend.execute(@clear)
        self
      end

      # (see Proxy#close)
      def close
        backend.close_async
        @backend = nil
        if @own_cluster
          @own_cluster.close_async
          @own_cluster = nil
        end
        nil
      end

      # (see Proxy#each_key)
      def each_key
        rc, = consistency
        return enum_for(:each_key) unless block_given?
        result = backend.execute(@each_key, consistency: rc, page_size: 100)
        loop do
          result.each do |row|
            next if row[config.expired_column] == nil
            yield row[config.key_column]
          end

          break if result.last_page?
          result = result.next_page
        end
        self
      end

      # (see Proxy#slice)
      def slice(*keys, **options)
        rc, wc = consistency(options)
        result = backend.execute(@slice, options.merge(consistency: rc, arguments: [keys]))
        expires = expires_value(options, nil)
        updated = [] if expires != nil
        pairs = result.map do |row|
          next if row[config.expired_column] == nil
          if expires != nil
            updated << [row[config.key_column], row[config.value_column], row[config.updated_column]]
          end
          [row[config.key_column], row[config.value_column]]
        end.compact

        if expires != nil && !updated.empty?
          ttl = (expires || 0).to_i
          t = timestamp
          batch = backend.batch do |batch|
            updated.each do |key, value, updated|
              batch.add(@update_expires, arguments: [ttl, t, value, key, updated])
            end
          end

          backend.execute(batch, options.merge(consistency: wc))
        end

        pairs
      end

      # (see Proxy#values_at)
      def values_at(*keys, **options)
        hash = Hash[slice(*keys, **options)]
        keys.map { |key| hash[key] }
      end

      # (see Proxy#fetch_values)
      def fetch_values(*keys, **options)
        return values_at(*keys, **options) unless block_given?
        hash = Hash[slice(*keys, **options)]
        keys.map do |key|
          if hash.key?(key)
            hash[key]
          else
            yield key
          end
        end
      end

      # (see Proxy#merge!)
      def merge!(pairs, options = {})
        keys = pairs.map { |k, _| k }.to_a
        return self if keys.empty?

        if block_given?
          existing = Hash[slice(*keys, **options)]
          pairs = pairs.map do |key, new_value|
            if existing.key?(key)
              [key, yield(key, existing[key], new_value)]
            else
              [key, new_value]
            end
          end
        end

        _rc, wc = consistency(options)
        expires = expires_value(options)
        t = timestamp
        batch = backend.batch do |batch|
          batch.add(@merge_delete, arguments: [t, keys])
          pairs.each do |key, value|
            batch.add(@store, arguments: [key, value, (expires || 0).to_i, t + 1])
          end
        end
        backend.execute(batch, options.merge(consistency: wc))

        self
      end

      private

      def timestamp
        (Time.now.to_r * 1_000_000).to_i
      end

      def create_keyspace(backend, keyspace, create_keyspace)
        options = {
          replication: {
            class: 'SimpleStrategy',
            replication_factor: 1
          }
        }

        case create_keyspace
        when Proc
          return create_keyspace.call(keyspace)
        when false
          return
        when Hash
          options.merge!(create_keyspace)
        end

        # This is a bit hacky, but works.  Options in Cassandra look like JSON,
        # but use single quotes instead of double-quotes.
        require 'multi_json'
        option_str = options.map do |key, value|
          key.to_s + ' = ' + MultiJson.dump(value).tr(?", ?')
        end.join(' AND ')

        backend.execute "CREATE KEYSPACE IF NOT EXISTS %<keyspace>s WITH %<options>s" % {
          keyspace: keyspace,
          options: option_str
        }
      rescue ::Cassandra::Errors::TimeoutError
        tries ||= 0
        (tries += 1) <= 3 ? retry : raise
      end

      def prepare_statements
        @key = backend.prepare(<<-CQL)
          SELECT #{config.updated_column}, #{config.expired_column}
          FROM #{config.table} WHERE #{config.key_column} = ?
          LIMIT 1
        CQL
        @store_delete = backend.prepare(<<-CQL)
          DELETE FROM #{config.table}
          USING TIMESTAMP ?
          WHERE #{config.key_column} = ?
        CQL
        @store = backend.prepare(<<-CQL)
          INSERT INTO #{config.table} (#{config.key_column}, #{config.value_column}, #{config.updated_column}, #{config.expired_column})
          VALUES (?, ?, now(), false)
          USING TTL ? AND TIMESTAMP ?
        CQL
        @load = backend.prepare(<<-CQL)
          SELECT #{config.value_column}, #{config.updated_column}, #{config.expired_column}
          FROM #{config.table}
          WHERE #{config.key_column} = ?
          LIMIT 1
        CQL
        @update_expires = backend.prepare(<<-CQL)
          UPDATE #{config.table}
          USING TTL ? AND TIMESTAMP ?
          SET #{config.value_column} = ?, #{config.expired_column} = false
          WHERE #{config.key_column} = ? AND #{config.updated_column} = ?
        CQL
        @clear = backend.prepare("TRUNCATE #{config.table}")
        @delete_value = backend.prepare(<<-CQL)
          SELECT #{config.value_column}, #{config.updated_column}, #{config.expired_column}
          FROM #{config.table}
          WHERE #{config.key_column} = ?
          LIMIT 1
        CQL
        @delete = backend.prepare(<<-CQL, idempotent: true)
          DELETE FROM #{config.table}
          USING TIMESTAMP ?
          WHERE #{config.key_column} = ? AND #{config.updated_column} = ?
        CQL
        @each_key = backend.prepare(<<-CQL)
          SELECT #{config.key_column}, #{config.expired_column}
          FROM #{config.table}
        CQL
        @slice = backend.prepare(<<-CQL)
          SELECT #{config.key_column}, #{config.value_column}, #{config.updated_column}, #{config.expired_column}
          FROM #{config.table}
          WHERE #{config.key_column} IN ?
        CQL
        @merge_delete = backend.prepare(<<-CQL)
          DELETE FROM #{config.table}
          USING TIMESTAMP ?
          WHERE #{config.key_column} IN ?
        CQL
      end

      def consistency(options = {})
        [
          options[:read_consistency] || config.read_consistency,
          options[:write_consistency] || config.write_consistency
        ]
      end
    end
  end
end
