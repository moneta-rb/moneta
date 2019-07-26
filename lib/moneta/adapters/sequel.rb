require 'sequel'

module Moneta
  module Adapters
    # Sequel backend
    # @api public
    class Sequel
      include Defaults

      # Sequel::UniqueConstraintViolation is defined since sequel 3.44.0
      # older versions raise a Sequel::DatabaseError.
      UniqueConstraintViolation = defined?(::Sequel::UniqueConstraintViolation) ? ::Sequel::UniqueConstraintViolation : ::Sequel::DatabaseError

      supports :create, :increment, :each_key
      attr_reader :backend, :key_column, :value_column

      # @param [Hash] options
      # @option options [String] :db Sequel database
      # @option options [String, Symbol] :table (:moneta) Table name
      # @option options [Array] :extensions ([]) List of Sequel extensions
      # @option options [Integer] :connection_validation_timeout (nil) Sequel connection_validation_timeout
      # @option options [Sequel::Database] :backend Use existing backend instance
      # @option options [Boolean] :optimize (true) Set to false to prevent database-specific optimisations
      # @option options [Proc, Boolean] :create_table Provide a Proc for creating the table, or
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
      def self.new(options = {})
        extensions = options.delete(:extensions)
        connection_validation_timeout = options.delete(:connection_validation_timeout)
        optimize = options.delete(:optimize)
        backend = options.delete(:backend) ||
          begin
            raise ArgumentError, 'Option :db is required' unless db = options.delete(:db)
            other_cols = [:table, :create_table, :key_column, :value_column, :hstore]
            ::Sequel.connect(db, options.reject { |k,| other_cols.member?(k) }).tap do |backend|
              if extensions
                raise ArgumentError, 'Option :extensions must be an Array' unless extensions.is_a?(Array)
                extensions.map(&:to_sym).each(&backend.method(:extension))
              end

              if connection_validation_timeout
                backend.pool.connection_validation_timeout = connection_validation_timeout
              end
            end
          end

        instance =
          if optimize == nil || optimize
            case backend.database_type
            when :mysql
              MySQL.allocate
            when :postgres
              if options[:hstore]
                PostgresHStore.allocate
              elsif matches = backend.get(::Sequel[:version].function).match(/PostgreSQL (\d+)\.(\d+)/)
                # Our optimisations only work on Postgres 9.5+
                major, minor = matches[1..2].map(&:to_i)
                Postgres.allocate if major > 9 || (major == 9 && minor >= 5)
              end
            when :sqlite
              SQLite.allocate
            end
          end || allocate

        instance.instance_variable_set(:@backend, backend)
        instance.send(:initialize, options)
        instance
      end

      # @api private
      def initialize(options)
        @table_name = (options.delete(:table) || :moneta).to_sym
        @key_column = options.delete(:key_column) || :k
        @value_column = options.delete(:value_column) || :v
        @each_key_server = options.delete(:each_key_server)

        create_proc = options.delete(:create_table)
        if create_proc == nil
          create_table
        elsif create_proc
          create_proc.call(@backend)
        end

        @table = @backend[@table_name]
        prepare_statements
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @key.call(key: key) != nil
      end

      # (see Proxy#load)
      def load(key, options = {})
        if row = @load.call(key: key)
          row[value_column]
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
      rescue UniqueConstraintViolation
        false
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @backend.transaction do
          if existing = @load_for_update.call(key: key)
            existing_value = existing[value_column]
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
        @backend.disconnect
        nil
      end

      # (see Proxy#slice)
      def slice(*keys, **options)
        @slice.all(keys).map! { |row| [row[key_column], row[value_column]] }
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
        @backend.transaction do
          existing = Hash[slice_for_update(pairs)]
          update_pairs, insert_pairs = pairs.partition { |k, _| existing.key?(k) }
          @table.import([key_column, value_column], blob_pairs(insert_pairs))

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
        if @each_key_server
          @table.server(@each_key_server).order(key_column).select(key_column).paged_each do |row|
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

      def blob(str)
        ::Sequel.blob(str) unless str == nil
      end

      def blob_pairs(pairs)
        pairs.map do |key, value|
          [key, blob(value)]
        end
      end

      def create_table
        key_column = self.key_column
        value_column = self.value_column
        @backend.create_table?(@table_name) do
          String key_column, null: false, primary_key: true
          File value_column
        end
      end

      def slice_for_update(pairs)
        @slice_for_update.all(pairs.map { |k, _| k }.to_a).map! do |row|
          [row[key_column], row[value_column]]
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
        "moneta_#{@table_name}_#{id}".to_sym
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
          .where(key_column => :$key).select(1)
          .prepare(:first, statement_id(:key))
      end

      def prepare_load
        @load = @table
          .where(key_column => :$key).select(value_column)
          .prepare(:first, statement_id(:load))
      end

      def prepare_store
        @store_update = @table
          .where(key_column => :$key)
          .prepare(:update, statement_id(:store_update), value_column => :$value)
      end

      def prepare_create
        @create = @table
          .prepare(:insert, statement_id(:create), key_column => :$key, value_column => :$value)
      end

      def prepare_increment
        @load_for_update = @table
          .where(key_column => :$key).for_update
          .select(value_column)
          .prepare(:first, statement_id(:load_for_update))
        @increment_update ||= @table
          .where(key_column => :$key, value_column => :$value)
          .prepare(:update, statement_id(:increment_update), value_column => :$new_value)
      end

      def prepare_delete
        @delete = @table.where(key_column => :$key)
          .prepare(:delete, statement_id(:delete))
      end

      def prepare_slice
        @slice_for_update = ::Sequel::Dataset::PlaceholderLiteralizer.loader(@table) do |pl, ds|
          ds.filter(key_column => pl.arg).select(key_column, value_column).for_update
        end

        @slice = ::Sequel::Dataset::PlaceholderLiteralizer.loader(@table) do |pl, ds|
          ds.filter(key_column => pl.arg).select(key_column, value_column)
        end
      end

      # @api private
      class IncrementError < ::Sequel::DatabaseError; end

      # @api private
      class MySQL < Sequel
        def store(key, value, options = {})
          @store.call(key: key, value: blob(value))
          value
        end

        def increment(key, amount = 1, options = {})
          @backend.transaction do
            # this creates a row-level lock even if there is no existing row (a
            # "gap lock").
            if row = @load_for_update.call(key: key)
              # Integer() will raise an exception if the existing value cannot be parsed
              amount += Integer(row[value_column])
              @increment_update.call(key: key, value: amount)
            else
              @create.call(key: key, value: amount)
            end
            amount
          end
        rescue ::Sequel::SerializationFailure # Thrown on deadlock
          tries ||= 0
          (tries += 1) <= 3 ? retry : raise
        end

        def merge!(pairs, options = {}, &block)
          @backend.transaction do
            pairs = yield_merge_pairs(pairs, &block) if block_given?
            @table
              .on_duplicate_key_update
              .import([key_column, value_column], blob_pairs(pairs).to_a)
          end

          self
        end

        def each_key
          return super unless block_given? && @each_key_server && @table.respond_to?(:stream)
          # Order is not required when streaming
          @table.server(@each_key_server).select(key_column).paged_each do |row|
            yield row[key_column]
          end
          self
        end

        protected

        def prepare_store
          @store = @table
            .on_duplicate_key_update
            .prepare(:insert, statement_id(:store), key_column => :$key, value_column => :$value)
        end

        def prepare_increment
          @increment_update = @table
            .where(key_column => :$key)
            .prepare(:update, statement_id(:increment_update), value_column => :$value)
          super
        end
      end

      # @api private
      class Postgres < Sequel
        def store(key, value, options = {})
          @store.call(key: key, value: blob(value))
          value
        end

        def increment(key, amount = 1, options = {})
          result = @increment.call(key: key, value: blob(amount.to_s), amount: amount)
          if row = result.first
            row[value_column].to_i
          end
        end

        def delete(key, options = {})
          result = @delete.call(key: key)
          if row = result.first
            row[value_column]
          end
        end

        def merge!(pairs, options = {}, &block)
          @backend.transaction do
            pairs = yield_merge_pairs(pairs, &block) if block_given?
            @table
              .insert_conflict(target: key_column,
                               update: { value_column => ::Sequel[:excluded][value_column] })
              .import([key_column, value_column], blob_pairs(pairs).to_a)
          end

          self
        end

        def each_key
          return super unless block_given? && !@each_key_server && @table.respond_to?(:use_cursor)
          # With a cursor, this will Just Work.
          @table.select(key_column).paged_each do |row|
            yield row[key_column]
          end
          self
        end

        protected

        def prepare_store
          @store = @table
            .insert_conflict(target: key_column,
                             update: { value_column => ::Sequel[:excluded][value_column] })
            .prepare(:insert, statement_id(:store), key_column => :$key, value_column => :$value)
        end

        def prepare_increment
          update_expr = ::Sequel[:convert_to].function(
            (::Sequel[:convert_from].function(
              ::Sequel[@table_name][value_column],
              'UTF8'
            ).cast(Integer) + :$amount).cast(String),
            'UTF8'
          )

          @increment = @table
            .returning(value_column)
            .insert_conflict(target: key_column, update: { value_column => update_expr })
            .prepare(:insert, statement_id(:increment), key_column => :$key, value_column => :$value)
        end

        def prepare_delete
          @delete = @table
            .returning(value_column)
            .where(key_column => :$key)
            .prepare(:delete, statement_id(:delete))
        end
      end

      # @api private
      class PostgresHStore < Sequel
        def initialize(options)
          @row = options.delete(:hstore).to_s
          @backend.extension :pg_hstore
          ::Sequel.extension :pg_hstore_ops
          @backend.extension :pg_array
          super
        end

        def key?(key, options = {})
          if @key
            row = @key.call(row: @row, key: key) || false
            row && row[:present]
          else
            @key_pl.get(key)
          end
        end

        def store(key, value, options = {})
          @backend.transaction do
            create_row
            @store.call(row: @row, pair: ::Sequel.hstore(key => value))
          end
          value
        end

        def load(key, options = {})
          if row = @load.call(row: @row, key: key)
            row[:value]
          end
        end

        def delete(key, options = {})
          @backend.transaction do
            value = load(key, options)
            @delete.call(row: @row, key: key)
            value
          end
        end

        def increment(key, amount = 1, options = {})
          @backend.transaction do
            create_row
            if row = @increment.call(row: @row, key: key, amount: amount).first
              row[:value].to_i
            end
          end
        end

        def create(key, value, options = {})
          @backend.transaction do
            create_row
            1 ==
              if @create
                @create.call(row: @row, key: key, pair: ::Sequel.hstore(key => value))
              else
                @table
                  .where(key_column => @row)
                  .exclude(::Sequel[value_column].hstore.key?(key))
                  .update(value_column => ::Sequel[value_column].hstore.merge(key => value))
              end
          end
        end

        def clear(options = {})
          @clear.call(row: @row)
          self
        end

        def values_at(*keys, **options)
          if row = @values_at.call(row: @row, keys: ::Sequel.pg_array(keys))
            row[:values].to_a
          else
            []
          end
        end

        def slice(*keys, **options)
          if row = @slice.call(row: @row, keys: ::Sequel.pg_array(keys))
            row[:pairs].to_h
          else
            []
          end
        end

        def merge!(pairs, options = {}, &block)
          @backend.transaction do
            create_row
            pairs = yield_merge_pairs(pairs, &block) if block_given?
            hash = Hash === pairs ? pairs : Hash[pairs.to_a]
            @store.call(row: @row, pair: ::Sequel.hstore(hash))
          end

          self
        end

        def each_key
          return enum_for(:each_key) { @size.call(row: @row)[:size] } unless block_given?

          ds =
            if @each_key_server
              @table.server(@each_key_server)
            else
              @table
            end
          ds = ds.order(:skeys) unless @table.respond_to?(:use_cursor)
          ds.where(key_column => @row)
            .select(::Sequel[value_column].hstore.skeys)
            .paged_each do |row|
              yield row[:skeys]
            end
          self
        end

        protected

        def create_row
          @create_row.call(row: @row)
        end

        def create_table
          key_column = self.key_column
          value_column = self.value_column

          @backend.create_table?(@table_name) do
            column key_column, String, null: false, primary_key: true
            column value_column, :hstore
            index value_column, type: :gin
          end
        end

        def slice_for_update(pairs)
          keys = pairs.map { |k, _| k }.to_a
          if row = @slice_for_update.call(row: @row, keys: ::Sequel.pg_array(keys))
            row[:pairs].to_h
          else
            {}
          end
        end

        def prepare_statements
          super
          prepare_create_row
          prepare_clear
          prepare_values_at
          prepare_size
        end

        def prepare_create_row
          @create_row = @table
            .insert_ignore
            .prepare(:insert, statement_id(:hstore_create_row), key_column => :$row, value_column => '')
        end

        def prepare_clear
          @clear = @table.where(key_column => :$row).prepare(:update, statement_id(:hstore_clear), value_column => '')
        end

        def prepare_key
          if defined?(JRUBY_VERSION)
            @key_pl = ::Sequel::Dataset::PlaceholderLiteralizer.loader(@table) do |pl, ds|
              ds.where(key_column => @row).select(::Sequel[value_column].hstore.key?(pl.arg))
            end
          else
            @key = @table.where(key_column => :$row)
              .select(::Sequel[value_column].hstore.key?(:$key).as(:present))
              .prepare(:first, statement_id(:hstore_key))
          end
        end

        def prepare_store
          @store = @table
            .where(key_column => :$row)
            .prepare(:update, statement_id(:hstore_store), value_column => ::Sequel[value_column].hstore.merge(:$pair))
        end

        def prepare_increment
          pair = ::Sequel[:hstore]
            .function(:$key, (
              ::Sequel[:coalesce].function(::Sequel[value_column].hstore[:$key].cast(Integer), 0) +
              :$amount
            ).cast(String))

          @increment = @table
            .returning(::Sequel[value_column].hstore[:$key].as(:value))
            .where(key_column => :$row)
            .prepare(:update, statement_id(:hstore_increment), value_column => ::Sequel.join([value_column, pair]))
        end

        def prepare_load
          @load = @table.where(key_column => :$row)
            .select(::Sequel[value_column].hstore[:$key].as(:value))
            .prepare(:first, statement_id(:hstore_load))
        end

        def prepare_delete
          @delete = @table.where(key_column => :$row)
            .prepare(:update, statement_id(:hstore_delete), value_column => ::Sequel[value_column].hstore.delete(:$key))
        end

        def prepare_create
          # Under JRuby we can't use a prepared statement for queries involving
          # the hstore `?` (key?) operator.  See
          # https://stackoverflow.com/questions/11940401/escaping-hstore-contains-operators-in-a-jdbc-prepared-statement
          return if defined?(JRUBY_VERSION)
          @create = @table
            .where(key_column => :$row)
            .exclude(::Sequel[value_column].hstore.key?(:$key))
            .prepare(:update, statement_id(:hstore_create), value_column => ::Sequel[value_column].hstore.merge(:$pair))
        end

        def prepare_values_at
          @values_at = @table
            .where(key_column => :$row)
            .select(::Sequel[value_column].hstore[::Sequel.cast(:$keys, :"text[]")].as(:values))
            .prepare(:first, statement_id(:hstore_values_at))
        end

        def prepare_slice
          slice = @table
            .where(key_column => :$row)
            .select(::Sequel[value_column].hstore.slice(:$keys).as(:pairs))
          @slice = slice.prepare(:first, statement_id(:hstore_slice))
          @slice_for_update = slice.for_update.prepare(:first, statement_id(:hstore_slice_for_update))
        end

        def prepare_size
          @size = @backend
            .from(@table.where(key_column => :$row)
                        .select(::Sequel[value_column].hstore.each))
            .select { count.function.*.as(:size) }
            .prepare(:first, statement_id(:hstore_size))
        end
      end

      # @api private
      class SQLite < Sequel
        def initialize(options)
          @version = backend.get(::Sequel[:sqlite_version].function)
          # See https://sqlite.org/lang_UPSERT.html
          @can_upsert = ::Gem::Version.new(@version) >= ::Gem::Version.new('3.24.0')
          super
        end

        def store(key, value, options = {})
          @table.insert_conflict(:replace).insert(key_column => key, value_column => blob(value))
          value
        end

        def increment(key, amount = 1, options = {})
          return super unless @can_upsert
          @backend.transaction do
            @increment.call(key: key, value: amount.to_s, amount: amount)
            Integer(load(key))
          end
        end

        def merge!(pairs, options = {}, &block)
          @backend.transaction do
            pairs = yield_merge_pairs(pairs, &block) if block_given?
            @table.insert_conflict(:replace).import([key_column, value_column], blob_pairs(pairs).to_a)
          end

          self
        end

        protected

        def prepare_store
          @store = @table
            .insert_conflict(:replace)
            .prepare(:insert, statement_id(:store), key_column => :$key, value_column => :$value)
        end

        def prepare_increment
          return super unless @can_upsert
          update_expr = (::Sequel[value_column].cast(Integer) + :$amount).cast(:blob)
          @increment = @table
            .insert_conflict(
              target: key_column,
              update: { value_column => update_expr },
              update_where: ::Sequel.|(
                { value_column => blob("0") },
                ::Sequel.~(::Sequel[value_column].cast(Integer)) => 0
              )
            )
            .prepare(:insert, statement_id(:increment), key_column => :$key, value_column => :$value)
        end
      end
    end
  end
end
