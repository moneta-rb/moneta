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
      # @option options All other options passed to `Sequel#connect`
      def self.new(options = {})
        extensions = options.delete(:extensions)
        connection_validation_timeout = options.delete(:connection_validation_timeout)
        optimize = options.delete(:optimize)
        backend = options.delete(:backend) ||
          begin
            raise ArgumentError, 'Option :db is required' unless db = options.delete(:db)
            other_cols = [:table, :create_table, :key_column, :value_column, :hstore]
            ::Sequel.connect(db, options.reject { |k,_| other_cols.member?(k) }).tap do |backend|
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
          if optimize.nil? || optimize
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

        create_proc = options.delete(:create_table)
        if create_proc.nil?
          create_table
        elsif create_proc
          create_proc.call(@backend)
        end

        @table = @backend[@table_name]
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        !@table.where(key_column => key).empty?
      end

      # (see Proxy#load)
      def load(key, options = {})
        @table.where(key_column => key).get(value_column)
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        blob_value = blob(value)
        unless @table.where(key_column => key).update(value_column => blob_value) == 1
          @table.insert(key_column => key, value_column => blob_value)
        end
        value
      rescue ::Sequel::DatabaseError
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#store)
      def create(key, value, options = {})
        @table.insert(key_column => key, value_column => blob(value))
        true
      rescue UniqueConstraintViolation
        false
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @backend.transaction do
          if existing = @table.where(key_column => key).for_update.get(value_column)
            amount += Integer(existing)
            raise IncrementError, "no update" unless @table.
              where(key_column => key, value_column => existing).
              update(value_column => blob(amount.to_s)) == 1
          else
            @table.insert(key_column => key, value_column => blob(amount.to_s))
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
        @table.filter(key_column => key).delete
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
        @table.filter(key_column => keys).as_hash(key_column, value_column)
      end

      # (see Proxy#values_at)
      def values_at(*keys, **options)
        pairs = slice(*keys, **options)
        keys.map { |key| pairs[key] }
      end

      # (see Proxy#fetch_values)
      def fetch_values(*keys, **options)
        return values_at(*keys, **options) unless block_given?
        existing = slice(*keys, **options)
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
          existing = existing_for_update(pairs)
          update_pairs, insert_pairs = pairs.partition { |k, _| existing.key?(k) }
          @table.import([key_column, value_column], blob_pairs(insert_pairs))

          if block_given?
            update_pairs.map! do |key, new_value|
              [key, yield(key, existing[key], new_value)]
            end
          end

          update_pairs.each do |key, value|
            @table.filter(key_column => key).update(value_column => blob(value))
          end
        end

        self
      end

      # (see Proxy#each_key)
      def each_key
        return enum_for(:each_key) { @table.count } unless block_given?
        @table.select(key_column).each do |row|
          yield row[key_column]
        end
        self
      end

      protected

      # See https://github.com/jeremyevans/sequel/issues/715
      def blob(s)
        s.empty? ? '' : ::Sequel.blob(s)
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

      def existing_for_update(pairs)
        @table.
          filter(key_column => pairs.map { |k, _| k }.to_a).
          for_update.
          as_hash(key_column, value_column)
      end

      def yield_merge_pairs(pairs)
        existing = existing_for_update(pairs)
        pairs.map do |key, new_value|
          new_value = yield(key, existing[key], new_value) if existing.key?(key)
          [key, new_value]
        end
      end

      # @api private
      class IncrementError < ::Sequel::DatabaseError; end

      # @api private
      class MySQL < Sequel
        def store(key, value, options = {})
          @table.
            on_duplicate_key_update.
            insert(key_column => key, value_column => blob(value))
          value
        end

        def increment(key, amount = 1, options = {})
          @backend.transaction do
            # this creates a row-level lock even if there is no existing row (a
            # "gap lock").
            if existing = @table.where(key_column => key).for_update.get(value_column)
              # Integer() will raise an exception if the existing value cannot be parsed
              amount += Integer(existing)
              @table.where(key_column => key).update(value_column => amount)
            else
              @table.insert(key_column => key, value_column => amount)
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
            @table.
              on_duplicate_key_update.
              import([key_column, value_column], blob_pairs(pairs).to_a)
          end

          self
        end
      end

      # @api private
      class Postgres < Sequel
        def store(key, value, options = {})
          @table.
            insert_conflict(
              target: key_column,
              update: {value_column => ::Sequel[:excluded][value_column]}).
            insert(key_column => key, value_column => blob(value))
          value
        end

        def increment(key, amount = 1, options = {})
          update_expr = ::Sequel[:convert_to].function(
            (::Sequel[:convert_from].function(
              ::Sequel[@table_name][value_column],
              'UTF8').cast(Integer) + amount).cast(String),
            'UTF8')

          if row = @table.
            returning(value_column).
            insert_conflict(target: key_column, update: {value_column => update_expr}).
            insert(key_column => key, value_column => amount.to_s).
            first
          then
            row[value_column].to_i
          end
        end

        def delete(key, options = {})
          if row = @table.returning(value_column).where(key_column => key).delete.first
            row[value_column]
          end
        end

        def merge!(pairs, options = {}, &block)
          @backend.transaction do
            pairs = yield_merge_pairs(pairs, &block) if block_given?
            @table.
              insert_conflict(
                target: key_column,
                update: {value_column => ::Sequel[:excluded][value_column]}).
              import([key_column, value_column], blob_pairs(pairs).to_a)
          end

          self
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
          !!@table.where(key_column => @row).get(::Sequel[value_column].hstore.key?(key))
        end

        def store(key, value, options = {})
          create_row
          @table.
            where(key_column => @row).
            update(value_column => ::Sequel[@table_name][value_column].hstore.merge(key => value))
          value
        end

        def load(key, options = {})
          @table.where(key_column => @row).get(::Sequel[value_column].hstore[key])
        end

        def delete(key, options = {})
          value = load(key, options)
          @table.where(key_column => @row).update(value_column => ::Sequel[value_column].hstore.delete(key))
          value
        end

        def increment(key, amount = 1, options = {})
          create_row
          pair = ::Sequel[:hstore].function(
            key,
            (::Sequel[:coalesce].function(
              ::Sequel[value_column].hstore[key].cast(Integer),
              0) + amount).cast(String))

          if row = @table.
            returning(::Sequel[value_column].hstore[key].as(:value)).
            where(key_column => @row).
            update(value_column => ::Sequel.join([value_column, pair])).
            first
          then
            row[:value].to_i
          end
        end

        def create(key, value, options = {})
          create_row
          1 == @table.
            where(key_column => @row).
            exclude(::Sequel[value_column].hstore.key?(key)).
            update(value_column => ::Sequel[value_column].hstore.merge(key => value))
        end

        def clear(options = {})
          @table.where(key_column => @row).update(value_column => '')
          self
        end

        def values_at(*keys, **options)
          @table.
            where(key_column => @row).
            get(::Sequel[value_column].hstore[::Sequel.pg_array(keys)]).to_a
        end

        def slice(*keys, **options)
          @table.where(key_column => @row).get(::Sequel[value_column].hstore.slice(keys)).to_h
        end

        def merge!(pairs, options = {}, &block)
          @backend.transaction do
            create_row
            pairs = yield_merge_pairs(pairs, &block) if block_given?
            hash = Hash === pairs ? pairs : Hash[pairs.to_a]
            @table.
              where(key_column => @row).
              update(value_column => ::Sequel[@table_name][value_column].hstore.merge(hash))
          end

          self
        end

        def each_key
          unless block_given?
            return enum_for(:each_key) do
              @backend.from(
                @table.
                  where(key_column => @row).
                  select(::Sequel[@table_name][value_column].hstore.each)).count
            end
          end
          first = false
          @table.
            where(key_column => @row).
            select(::Sequel[@table_name][value_column].hstore.skeys).
            each do |row|
              if first
                first = false
                next
              end
              yield row[:skeys]
            end
          self
        end

        protected

        def create_row
          @table.
            insert_ignore.
            insert(key_column => @row, value_column => '')
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

        def existing_for_update(pairs)
          @table.where(key_column => @row).for_update.
            get(::Sequel[value_column].hstore.slice(pairs.map { |k, _| k }.to_a)).to_h
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
          update_expr = (::Sequel[@table_name][value_column].cast(Integer) + amount).cast(:blob)

          @backend.transaction do
            @table.
              insert_conflict(
                target: key_column,
                update: {value_column => update_expr},
                update_where:
                  ::Sequel.|(
                    {value_column => blob("0")},
                    ::Sequel.~(::Sequel[@table_name][value_column].cast(Integer)) => 0)).
              insert(key_column => key, value_column => blob(amount.to_s))
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
      end
    end
  end
end
