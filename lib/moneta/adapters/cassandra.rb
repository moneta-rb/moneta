require 'cassandra'

module Moneta
  module Adapters
    # Cassandra backend
    # @api public
    class Cassandra
      include Defaults
      include ExpiresSupport

      attr_reader :backend

      supports :each_key

      # @param [Hash] options
      # @option options [String] :keyspace ('moneta') Cassandra keyspace
      # @option options [String] :table ('moneta') Cassandra table
      # @option options [String] :host ('127.0.0.1') Server host name
      # @option options [Integer] :port (9160) Server port
      # @option options [Integer] :expires Default expiration time
      # @option options [String] :key_column ('key') Name of the key column
      # @option options [String] :value_column ('value') Name of the value column
      # @option options [String] :updated_column ('updated_at') Name of the column used to track last update
      # @option options [String] :expired_column ('expired') Name of the column used to track expiry
      # @option options [Symbol] :read_consistency (:all) Default read consistency
      # @option options [Symbol] :wtite_consistency (:all) Default write consistency
      # @option options [::Cassandra::Session] :backend Existing session to use
      # @option options Other options passed to `Cassandra#new`
      def initialize(options = {})
        self.default_expires = options.delete(:expires)
        keyspace = options.delete(:keyspace) || 'moneta'

        @table = (options.delete(:column_family) || 'moneta').to_sym
        @key_column = options.delete(:key_column) || 'key'
        @value_column = options.delete(:value_column) || 'value'
        @updated_column = options.delete(:updated_column) || 'updated_at'
        @expired_column = options.delete(:expired_column) || 'expired'
        @read_consistency = options.delete(:read_consistency) || :all
        @write_consistency = options.delete(:write_consistency) || :all

        @backend = options.delete(:backend) ||
          begin
            ::Cassandra.cluster(options).connect(keyspace)
          rescue ::Cassandra::Errors::InvalidError
            @backend = ::Cassandra.cluster(options).connect
            create_keyspace(keyspace)
            @backend.execute("USE " + keyspace)
            @backend
          end

        @backend.execute <<-CQL
          CREATE TABLE IF NOT EXISTS #{@table} (
            #{@key_column} blob,
            #{@value_column} blob,
            #{@updated_column} timeuuid,
            #{@expired_column} boolean,
            PRIMARY KEY (#{@key_column}, #{@updated_column})
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
            row = @backend.execute(@load, options.merge(consistency: rc, arguments: [key])).first and
            row[@expired_column] != nil
          @backend.execute(@update_expires, options.merge(consistency: wc, arguments: [
            (expires || 0).to_i, timestamp, row[@value_column], key, row[@updated_column]
          ]))
          true
        elsif row = @backend.execute(@key, options.merge(consistency: rc, arguments: [key])).first
          row[@expired_column] != nil
        else
          false
        end
      end

      # (see Proxy#load)
      def load(key, options = {})
        rc, wc = consistency(options)
        if row = @backend.execute(@load, options.merge(consistency: rc, arguments: [key])).first and row[@expired_column] != nil
          if (expires = expires_value(options, nil)) != nil
            @backend.execute(@update_expires, options.merge(consistency: wc, arguments: [
              (expires || 0).to_i, timestamp, row[@value_column], key, row[@updated_column]
            ]))
          end
          row[@value_column]
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        _, wc = consistency(options)
        expires = expires_value(options)
        t = timestamp
        batch = @backend.batch do |batch|
          batch.add(@store_delete, arguments: [t, key])
          batch.add(@store, arguments: [key, value, (expires || 0).to_i, t + 1])
        end
        @backend.execute(batch, options.merge(consistency: wc))
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        rc, wc = consistency(options)
        result = @backend.execute(@delete_value, options.merge(consistency: rc, arguments: [key]))
        if row = result.first and row[@expired_column] != nil
          @backend.execute(@delete, options.merge(consistency: wc, arguments: [timestamp, key, row[@updated_column]]))
          row[@value_column]
        end
      end

      # (see Proxy#clear)
      def clear(options = {})
        @backend.execute(@clear)
        self
      end

      # (see Proxy#close)
      def close
        @backend.close
        @backend = nil
        nil
      end

      # (see Proxy#each_key)
      def each_key
        rc, _ = consistency
        return enum_for(:each_key) unless block_given?
        result = @backend.execute(@each_key, consistency: rc, page_size: 100)
        loop do
          result.each do |row|
            next if row[@expired_column] == nil
            yield row[@key_column]
          end

          break if result.last_page?
          result = result.next_page
        end
        self
      end

      # (see Proxy#slice)
      def slice(*keys, **options)
        rc, wc = consistency(options)
        result = @backend.execute(@slice, options.merge(consistency: rc, arguments: [keys]))
        expires = expires_value(options, nil)
        updated = [] if expires != nil
        pairs = result.map do |row|
          next if row[@expired_column] == nil
          if expires != nil
            updated << [row[@key_column], row[@value_column], row[@updated_column]]
          end
          [row[@key_column], row[@value_column]]
        end.compact

        if expires != nil && !updated.empty?
          ttl = (expires || 0).to_i
          t = timestamp
          batch = @backend.batch do |batch|
            updated.each do |key, value, updated|
              batch.add(@update_expires, arguments: [ttl, t, value, key, updated])
            end
          end

          @backend.execute(batch, options.merge(consistency: wc))
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

        rc, wc = consistency(options)
        expires = expires_value(options)
        t = timestamp
        batch = @backend.batch do |batch|
          batch.add(@merge_delete, arguments: [t, keys])
          pairs.each do |key, value|
            batch.add(@store, arguments: [key, value, (expires || 0).to_i, t + 1])
          end
        end
        @backend.execute(batch, options.merge(consistency: wc))

        self
      end

      private

      def timestamp
        (Time.now.to_r * 1_000_000).to_i
      end

      def create_keyspace(keyspace)
        @backend.execute <<-CQL
          CREATE KEYSPACE IF NOT EXISTS #{keyspace}
          WITH replication = {
            'class': 'SimpleStrategy',
            'replication_factor': 1
          }
        CQL
      rescue ::Cassandra::Errors::TimeoutError
        tries ||= 0
        if (tries += 1) <= 3; retry else raise end
      end

      def prepare_statements
        @key = @backend.prepare(<<-CQL)
          SELECT #{@updated_column}, #{@expired_column}
          FROM #{@table} WHERE #{@key_column} = ?
          LIMIT 1
        CQL
        @store_delete = @backend.prepare(<<-CQL)
          DELETE FROM #{@table}
          USING TIMESTAMP ?
          WHERE #{@key_column} = ?
        CQL
        @store = @backend.prepare(<<-CQL)
          INSERT INTO #{@table} (#{@key_column}, #{@value_column}, #{@updated_column}, #{@expired_column})
          VALUES (?, ?, now(), false)
          USING TTL ? AND TIMESTAMP ?
        CQL
        @load = @backend.prepare(<<-CQL)
          SELECT #{@value_column}, #{@updated_column}, #{@expired_column}
          FROM #{@table}
          WHERE #{@key_column} = ?
          LIMIT 1
        CQL
        @update_expires = @backend.prepare(<<-CQL)
          UPDATE #{@table}
          USING TTL ? AND TIMESTAMP ?
          SET #{@value_column} = ?, #{@expired_column} = false
          WHERE #{@key_column} = ? AND #{@updated_column} = ?
        CQL
        @clear = @backend.prepare("TRUNCATE #{@table}")
        @delete_value = @backend.prepare(<<-CQL)
          SELECT #{@value_column}, #{@updated_column}, #{@expired_column}
          FROM #{@table}
          WHERE #{@key_column} = ?
          LIMIT 1
        CQL
        @delete = @backend.prepare(<<-CQL, idempotent: true)
          DELETE FROM #{@table}
          USING TIMESTAMP ?
          WHERE #{@key_column} = ? AND #{@updated_column} = ?
        CQL
        @each_key = @backend.prepare(<<-CQL)
          SELECT #{@key_column}, #{@expired_column}
          FROM #{@table}
        CQL
        @slice = @backend.prepare(<<-CQL)
          SELECT #{@key_column}, #{@value_column}, #{@updated_column}, #{@expired_column}
          FROM #{@table}
          WHERE #{@key_column} IN ?
        CQL
        @merge_delete = @backend.prepare(<<-CQL)
          DELETE FROM #{@table}
          USING TIMESTAMP ?
          WHERE #{@key_column} IN ?
        CQL
      end

      def consistency(options={})
        [
          options[:read_consistency] || @read_consistency,
          options[:write_consistency] || @write_consistency
        ]
      end
    end
  end
end
