require 'sequel'

module Moneta
  module Adapters
    # Sequel backend
    # @api public
    class Sequel < Adapter
      autoload :MySQL, 'moneta/adapters/sequel/mysql'
      autoload :Postgres, 'moneta/adapters/sequel/postgres'
      autoload :PostgresHStore, 'moneta/adapters/sequel/postgres_hstore'
      autoload :SQLite, 'moneta/adapters/sequel/sqlite'

      supports :create, :increment, :each_key

      config :table, default: :moneta, coerce: :to_sym
      config :optimize, default: true
      config :create_table, default: true
      config :key_column, default: :k
      config :value_column, default: :v
      config :hstore, coerce: :to_s
      config :each_key_server

      backend do |db:, extensions: [], connection_validation_timeout: nil, **options|
        ::Sequel.connect(db, options).tap do |backend|
          extensions.map(&:to_sym).each(&backend.method(:extension))

          if connection_validation_timeout
            backend.pool.connection_validation_timeout = connection_validation_timeout
          end
        end
      end

      # @param [Hash] options
      # @option options [String] :db Sequel database
      # @option options [String, Symbol] :table (:moneta) Table name
      # @option options [Array] :extensions ([]) List of Sequel extensions
      # @option options [Integer] :connection_validation_timeout (nil) Sequel connection_validation_timeout
      # @option options [Sequel::Database] :backend Use existing backend instance
      # @option options [Boolean] :optimize (true) Set to false to prevent database-specific optimisations
      # @option options [Proc, Boolean] :create_table (true) Provide a Proc for creating the table, or
      #   set to false to disable table creation all together.  If a Proc is given, it will be
      #   called regardless of whether the table exists already.
      # @option options [Symbol] :key_column (:k) The name of the key column
      # @option options [Symbol] :value_column (:v) The name of the value column
      # @option options [String] :hstore If using Postgres, keys and values are stored in a single
      #   row of the table in the value_column using the hstore format.  The row to use is
      #   the one where the value_column is equal to the value of this option, and will be created
      #   if it doesn't exist.
      # @option options [Symbol] :each_key_server Some adapters are unable to do
      #   multiple operations with a single connection. For these, it is
      #   possible to specify a separate connection to use for `#each_key`.  Use
      #   in conjunction with Sequel's `:servers` option
      # @option options All other options passed to `Sequel#connect`
      def initialize(options = {})
        super

        if config.hstore
          extend Sequel::PostgresHStore
        elsif config.optimize
          add_optimizations
        end

        if config.create_table.respond_to?(:call)
          config.create_table.call(backend)
        elsif config.create_table
          create_table
        end

        @table = backend[config.table]
        prepare_statements
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @key.call(key: key) != nil
      end

      # (see Proxy#load)
      def load(key, options = {})
        if row = @load.call(key: key)
          row[config.value_column]
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        blob_value = blob(value)
        unless @store_update.call(key: key, value: blob_value) == 1
          @create.call(key: key, value: blob_value)
        end
        value
      rescue ::Sequel::DatabaseError
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        @create.call(key: key, value: blob(value))
        true
      rescue ::Sequel::ConstraintViolation
        false
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        backend.transaction do
          if existing = @load_for_update.call(key: key)
            existing_value = existing[config.value_column]
            amount += Integer(existing_value)
            raise IncrementError, "no update" unless @increment_update.call(
              key: key,
              value: existing_value,
              new_value: blob(amount.to_s)
            ) == 1
          else
            @create.call(key: key, value: blob(amount.to_s))
          end
          amount
        end
      rescue ::Sequel::DatabaseError
        # Concurrent modification might throw a bunch of different errors
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = load(key, options)
        @delete.call(key: key)
        value
      end

      # (see Proxy#clear)
      def clear(options = {})
        @table.delete
        self
      end

      # (see Proxy#close)
      def close
        backend.disconnect
        nil
      end

      # (see Proxy#slice)
      def slice(*keys, **options)
        @slice.all(keys).map! { |row| [row[config.key_column], row[config.value_column]] }
      end

      # (see Proxy#values_at)
      def values_at(*keys, **options)
        pairs = Hash[slice(*keys, **options)]
        keys.map { |key| pairs[key] }
      end

      # (see Proxy#fetch_values)
      def fetch_values(*keys, **options)
        return values_at(*keys, **options) unless block_given?
        existing = Hash[slice(*keys, **options)]
        keys.map do |key|
          if existing.key? key
            existing[key]
          else
            yield key
          end
        end
      end

      # (see Proxy#merge!)
      def merge!(pairs, options = {})
        backend.transaction do
          existing = Hash[slice_for_update(pairs)]
          update_pairs, insert_pairs = pairs.partition { |k, _| existing.key?(k) }
          @table.import([config.key_column, config.value_column], blob_pairs(insert_pairs))

          if block_given?
            update_pairs.map! do |key, new_value|
              [key, yield(key, existing[key], new_value)]
            end
          end

          update_pairs.each do |key, value|
            @store_update.call(key: key, value: blob(value))
          end
        end

        self
      end

      # (see Proxy#each_key)
      def each_key
        return enum_for(:each_key) { @table.count } unless block_given?

        key_column = config.key_column
        if config.each_key_server
          @table.server(config.each_key_server).order(key_column).select(key_column).paged_each do |row|
            yield row[key_column]
          end
        else
          @table.select(key_column).order(key_column).paged_each(stream: false) do |row|
            yield row[key_column]
          end
        end
        self
      end

      protected

      # @api private
      def add_optimizations
        case backend.database_type
        when :mysql
          extend Sequel::MySQL
        when :postgres
          if matches = backend.get(::Sequel[:version].function).match(/PostgreSQL (\d+)\.(\d+)/)
            # Our optimisations only work on Postgres 9.5+
            major, minor = matches[1..2].map(&:to_i)
            extend Sequel::Postgres if major > 9 || (major == 9 && minor >= 5)
          end
        when :sqlite
          extend Sequel::SQLite
        end
      end

      def blob(str)
        ::Sequel.blob(str) unless str == nil
      end

      def blob_pairs(pairs)
        pairs.map do |key, value|
          [key, blob(value)]
        end
      end

      def create_table
        key_column = config.key_column
        value_column = config.value_column
        backend.create_table?(config.table) do
          String key_column, null: false, primary_key: true
          File value_column
        end
      end

      def slice_for_update(pairs)
        @slice_for_update.all(pairs.map { |k, _| k }.to_a).map! do |row|
          [row[config.key_column], row[config.value_column]]
        end
      end

      def yield_merge_pairs(pairs)
        existing = Hash[slice_for_update(pairs)]
        pairs.map do |key, new_value|
          new_value = yield(key, existing[key], new_value) if existing.key?(key)
          [key, new_value]
        end
      end

      def statement_id(id)
        "moneta_#{config.table}_#{id}".to_sym
      end

      def prepare_statements
        prepare_key
        prepare_load
        prepare_store
        prepare_create
        prepare_increment
        prepare_delete
        prepare_slice
      end

      def prepare_key
        @key = @table
          .where(config.key_column => :$key).select(1)
          .prepare(:first, statement_id(:key))
      end

      def prepare_load
        @load = @table
          .where(config.key_column => :$key).select(config.value_column)
          .prepare(:first, statement_id(:load))
      end

      def prepare_store
        @store_update = @table
          .where(config.key_column => :$key)
          .prepare(:update, statement_id(:store_update), config.value_column => :$value)
      end

      def prepare_create
        @create = @table
          .prepare(:insert, statement_id(:create), config.key_column => :$key, config.value_column => :$value)
      end

      def prepare_increment
        @load_for_update = @table
          .where(config.key_column => :$key).for_update
          .select(config.value_column)
          .prepare(:first, statement_id(:load_for_update))
        @increment_update ||= @table
          .where(config.key_column => :$key, config.value_column => :$value)
          .prepare(:update, statement_id(:increment_update), config.value_column => :$new_value)
      end

      def prepare_delete
        @delete = @table.where(config.key_column => :$key)
          .prepare(:delete, statement_id(:delete))
      end

      def prepare_slice
        @slice_for_update = ::Sequel::Dataset::PlaceholderLiteralizer.loader(@table) do |pl, ds|
          ds.filter(config.key_column => pl.arg).select(config.key_column, config.value_column).for_update
        end

        @slice = ::Sequel::Dataset::PlaceholderLiteralizer.loader(@table) do |pl, ds|
          ds.filter(config.key_column => pl.arg).select(config.key_column, config.value_column)
        end
      end

      # @api private
      class IncrementError < ::Sequel::DatabaseError; end
    end
  end
end
