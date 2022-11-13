require 'active_record'
require 'uri'

module Moneta
  module Adapters
    # ActiveRecord as key/value stores
    # @api public
    class ActiveRecord < Adapter
      autoload :V5, 'moneta/adapters/activerecord/v5'
      include ::Moneta::Adapters::ActiveRecord::V5 if ::ActiveRecord.version < ::Gem::Version.new('6.0.0')

      @connection_lock = ::Mutex.new
      class << self
        attr_reader :connection_lock
      end

      supports :create, :increment, :each_key

      attr_reader :table
      delegate :with_connection, to: :connection_pool

      config :key_column, default: :k
      config :value_column, default: :v
      config :connection

      backend required: false do |table: :moneta, create_table: nil|
        # Ensure the table name is a symbol.
        table_name = table.to_sym

        if create_table == nil
          default_create_table(table_name)
        elsif create_table
          with_connection(&create_table)
        end

        @table = ::Arel::Table.new(table_name)

        # backend is only used if there's an existing ActiveRecord model
        nil
      end

      # @param [Hash] options
      # @option options [Object]               :backend A class object inheriting from ActiveRecord::Base to use as a table
      # @option options [String,Symbol]        :table (:moneta) Table name
      # @option options [Hash/String/Symbol]   :connection ActiveRecord connection configuration (`Hash` or `String`), or
      #   symbol giving the name of a Rails connection (e.g. :production)
      # @option options [Proc, Boolean]        :create_table Proc called with a connection if table
      #   needs to be created.  Pass false to skip the create table check all together.
      # @option options [Symbol]               :key_column (:k) The name of the column to use for keys
      # @option options [Symbol]               :value_column (:v) The name of the column to use for values
      def initialize(options = {})
        super

        # If a :backend was provided, use it to set the table
        @table = ::Arel::Table.new(backend.table_name) if backend
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        with_connection do |conn|
          sel = arel_sel_key(key).project(::Arel.sql('1'))
          result = conn.select_all(sel)
          !result.empty?
        end
      end

      # (see Proxy#each_key)
      def each_key(&block)
        with_connection do |conn|
          return enum_for(:each_key) { conn.select_value(arel_sel.project(table[config.key_column].count)) } unless block_given?
          conn.select_values(arel_sel.project(table[config.key_column])).each { |k| yield(k) }
        end
        self
      end

      # (see Proxy#load)
      def load(key, options = {})
        with_connection do |conn|
          conn_sel_value(conn, key)
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        with_connection do |conn|
          encoded = encode(conn, value)
          conn_ins(conn, key, encoded) unless conn_upd(conn, key, encoded) == 1
        end
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        with_connection do |conn|
          conn.transaction do
            sel = arel_sel_key(key).project(table[config.value_column]).lock
            value = decode(conn, conn.select_value(sel))

            del = arel_del.where(table[config.key_column].eq(key))
            conn.delete(del)

            value
          end
        end
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        with_connection do |conn|
          begin
            conn_ins(conn, key, amount.to_s)
            amount
          rescue ::ActiveRecord::RecordNotUnique
            conn.transaction do
              sel = arel_sel_key(key).project(table[config.value_column]).lock
              value = decode(conn, conn.select_value(sel))
              value = (value ? Integer(value) : 0) + amount
              # Re-raise if the upate affects no rows (i.e. row deleted after attempted insert,
              # before select for update)
              raise unless conn_upd(conn, key, value.to_s) == 1
              value
            end
          end
        end
      rescue ::ActiveRecord::RecordNotUnique, ::ActiveRecord::Deadlocked
        # This handles the "no row updated" issue, above, as well as deadlocks
        # which may occur on some adapters
        tries ||= 0
        (tries += 1) <= 3 ? retry : raise
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        with_connection do |conn|
          conn_ins(conn, key, value)
          true
        end
      rescue ::ActiveRecord::RecordNotUnique
        false
      end

      # (see Proxy#clear)
      def clear(options = {})
        with_connection do |conn|
          conn.delete(arel_del)
        end
        self
      end

      # (see Proxy#close)
      def close
        @table = nil
        @connection_pool = nil
      end

      # (see Proxy#slice)
      def slice(*keys, lock: false, **options)
        with_connection do |conn|
          conn.create_table(:slice_keys, temporary: true) do |t|
            t.string :key, null: false
          end

          begin
            temp_table = ::Arel::Table.new(:slice_keys)
            keys.each do |key|
              conn.insert ::Arel::InsertManager.new
                .into(temp_table)
                .insert([[temp_table[:key], key]])
            end

            sel = arel_sel
              .join(temp_table)
              .on(table[config.key_column].eq(temp_table[:key]))
              .project(table[config.key_column], table[config.value_column])
            sel = sel.lock if lock
            result = conn.select_all(sel)

            k = config.key_column.to_s
            v = config.value_column.to_s
            result.map do |row|
              [row[k], decode(conn, row[v])]
            end
          ensure
            conn.drop_table(:slice_keys)
          end
        end
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
        with_connection do |conn|
          conn.transaction do
            existing = Hash[slice(*pairs.map { |k, _| k }, lock: true, **options)]
            update_pairs, insert_pairs = pairs.partition { |k, _| existing.key?(k) }
            insert_pairs.each { |key, value| conn_ins(conn, key, encode(conn, value)) }

            if block_given?
              update_pairs.map! do |key, new_value|
                [key, yield(key, existing[key], new_value)]
              end
            end

            update_pairs.each { |key, value| conn_upd(conn, key, encode(conn, value)) }
          end
        end

        self
      end

      private

      def connection_pool
        if backend
          backend.connection_pool
        elsif config.connection
          @owner_name ||=
            case config.connection
            when Symbol, String
              config.connection.to_s
            when Hash
              hash = config.connection.clone
              [:username, 'username', :password, 'password'].each { |key| hash.delete(key) }
              'moneta?' + URI.encode_www_form(config.connection.to_a.sort)
            end

          connection_handler = ::ActiveRecord::Base.connection_handler
          connection_handler.retrieve_connection_pool(@owner_name) ||
            self.class.connection_lock.synchronize do
              connection_handler.retrieve_connection_pool(@owner_name) ||
                connection_handler.establish_connection(config.connection, owner_name: @owner_name)
            end
        else
          ::ActiveRecord::Base.connection_pool
        end
      end

      def default_create_table(table_name)
        with_connection do |conn|
          return if conn.table_exists?(table_name)

          # Prevent multiple connections from attempting to create the table simultaneously.
          self.class.connection_lock.synchronize do
            conn.create_table(table_name, id: false) do |t|
              # Do not use binary key (Issue #17)
              t.string config.key_column, null: false
              t.binary config.value_column
            end
            conn.add_index(table_name, config.key_column, unique: true)
          end
        end
      end

      def arel_del
        ::Arel::DeleteManager.new.from(table)
      end

      def arel_sel
        ::Arel::SelectManager.new.from(table)
      end

      def arel_upd
        ::Arel::UpdateManager.new.table(table)
      end

      def arel_sel_key(key)
        arel_sel.where(table[config.key_column].eq(key))
      end

      def conn_ins(conn, key, value)
        ins = ::Arel::InsertManager.new.into(table)
        ins.insert([[table[config.key_column], key], [table[config.value_column], value]])
        conn.insert ins
      end

      def conn_upd(conn, key, value)
        conn.update arel_upd.where(table[config.key_column].eq(key)).set([[table[config.value_column], value]])
      end

      def conn_sel_value(conn, key)
        decode(conn, conn.select_value(arel_sel_key(key).project(table[config.value_column])))
      end

      def encode(conn, value)
        if value == nil
          nil
        elsif conn.respond_to?(:escape_bytea)
          conn.escape_bytea(value)
        elsif defined?(::ActiveRecord::ConnectionAdapters::SQLite3Adapter) &&
            conn.is_a?(::ActiveRecord::ConnectionAdapters::SQLite3Adapter)
          Arel::Nodes::SqlLiteral.new("X'#{value.unpack('H*').first}'")
        else
          value
        end
      end

      def decode(conn, value)
        if value == nil
          nil
        elsif defined?(::ActiveModel::Type::Binary::Data) &&
            value.is_a?(::ActiveModel::Type::Binary::Data)
          value.to_s
        elsif conn.respond_to?(:unescape_bytea)
          conn.unescape_bytea(value)
        else
          value
        end
      end
    end
  end
end
