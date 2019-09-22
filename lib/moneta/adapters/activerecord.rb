require 'active_record'
require 'uri'

module Moneta
  module Adapters
    # ActiveRecord as key/value stores
    # @api public
    class ActiveRecord
      include Defaults

      supports :create, :increment, :each_key

      attr_reader :table, :key_column, :value_column
      delegate :with_connection, to: :connection_pool

      @connection_lock = ::Mutex.new
      class << self
        attr_reader :connection_lock
        delegate :configurations, :configurations=, :connection_handler, to: ::ActiveRecord::Base

        def retrieve_connection_pool(spec_name)
          connection_handler.retrieve_connection_pool(spec_name.to_s)
        end

        def establish_connection(spec_name)
          connection_lock.synchronize do
            if connection_pool = retrieve_connection_pool(spec_name)
              connection_pool
            else
              connection_handler.establish_connection(spec_name.to_sym)
            end
          end
        end

        def retrieve_or_establish_connection_pool(spec_name)
          retrieve_connection_pool(spec_name) || establish_connection(spec_name)
        end
      end

      # @param [Hash] options
      # @option options [Object]               :backend A class object inheriting from ActiveRecord::Base to use as a table
      # @option options [String]               :table ('moneta') Table name
      # @option options [Hash/String/Symbol]   :connection ActiveRecord connection configuration (`Hash` or `String`), or
      #   symbol giving the name of a Rails connection (e.g. :production)
      # @option options [Proc, Boolean]        :create_table Proc called with a connection if table
      #   needs to be created.  Pass false to skip the create table check all together.
      # @option options [Symbol]               :key_column (:k) The name of the column to use for keys
      # @option options [Symbol]               :value_column (:v) The name of the column to use for values
      def initialize(options = {})
        @key_column = options.delete(:key_column) || :k
        @value_column = options.delete(:value_column) || :v

        if backend = options.delete(:backend)
          @spec = backend.connection_pool.spec
          @table = ::Arel::Table.new(backend.table_name.to_sym)
        else
          # Feed the connection info into ActiveRecord and get back a name to use for getting the
          # connection pool
          connection = options.delete(:connection)
          @spec =
            case connection
            when Symbol
              connection
            when Hash, String
              # Normalize the connection specification to a hash
              resolver = ::ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new \
                'dummy' => connection

              # Turn the config into a standardised hash, sans a couple of bits
              hash = resolver.resolve(:dummy)
              hash.delete('name')
              hash.delete(:password) # For security
              # Make a name unique to this config
              name = 'moneta?' + URI.encode_www_form(hash.to_a.sort)
              # Add into configurations unless its already there (initially done without locking for
              # speed)
              unless self.class.configurations.key? name
                self.class.connection_lock.synchronize do
                  self.class.configurations[name] = connection \
                    unless self.class.configurations.key? name
                end
              end

              name.to_sym
            else
              ::ActiveRecord::Base.connection_pool.spec.name.to_s
            end

          table_name = (options.delete(:table) || :moneta).to_sym
          create_table_proc = options.delete(:create_table)
          if create_table_proc == nil
            create_table(table_name)
          elsif create_table_proc
            with_connection(&create_table_proc)
          end

          @table = ::Arel::Table.new(table_name)
        end
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
          return enum_for(:each_key) { conn.select_value(arel_sel.project(table[key_column].count)) } unless block_given?
          conn.select_values(arel_sel.project(table[key_column])).each { |k| yield(k) }
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
            sel = arel_sel_key(key).project(table[value_column]).lock
            value = decode(conn, conn.select_value(sel))

            del = arel_del.where(table[key_column].eq(key))
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
              sel = arel_sel_key(key).project(table[value_column]).lock
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
        @spec = nil
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
              .on(table[key_column].eq(temp_table[:key]))
              .project(table[key_column], table[value_column])
            sel = sel.lock if lock
            result = conn.select_all(sel)

            k = key_column.to_s
            v = value_column.to_s
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
        self.class.retrieve_or_establish_connection_pool(@spec)
      end

      def create_table(table_name)
        with_connection do |conn|
          return if conn.table_exists?(table_name)

          # Prevent multiple connections from attempting to create the table simultaneously.
          self.class.connection_lock.synchronize do
            conn.create_table(table_name, id: false) do |t|
              # Do not use binary key (Issue #17)
              t.string key_column, null: false
              t.binary value_column
            end
            conn.add_index(table_name, key_column, unique: true)
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
        arel_sel.where(table[key_column].eq(key))
      end

      def conn_ins(conn, key, value)
        ins = ::Arel::InsertManager.new.into(table)
        ins.insert([[table[key_column], key], [table[value_column], value]])
        conn.insert ins
      end

      def conn_upd(conn, key, value)
        conn.update arel_upd.where(table[key_column].eq(key)).set([[table[value_column], value]])
      end

      def conn_sel_value(conn, key)
        decode(conn, conn.select_value(arel_sel_key(key).project(table[value_column])))
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
