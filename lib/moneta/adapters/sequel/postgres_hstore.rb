::Sequel.extension :pg_hstore_ops

module Moneta
  module Adapters
    class Sequel
      # @api private
      module PostgresHStore
        def self.extended(mod)
          mod.backend.extension :pg_hstore
          mod.backend.extension :pg_array
        end

        def key?(key, options = {})
          if @key
            row = @key.call(row: config.hstore, key: key) || false
            row && row[:present]
          else
            @key_pl.get(key)
          end
        end

        def store(key, value, options = {})
          @backend.transaction do
            create_row
            @store.call(row: config.hstore, pair: ::Sequel.hstore(key => value))
          end
          value
        end

        def load(key, options = {})
          if row = @load.call(row: config.hstore, key: key)
            row[:value]
          end
        end

        def delete(key, options = {})
          @backend.transaction do
            value = load(key, options)
            @delete.call(row: config.hstore, key: key)
            value
          end
        end

        def increment(key, amount = 1, options = {})
          @backend.transaction do
            create_row
            if row = @increment.call(row: config.hstore, key: key, amount: amount).first
              row[:value].to_i
            end
          end
        end

        def create(key, value, options = {})
          @backend.transaction do
            create_row
            1 ==
              if @create
                @create.call(row: config.hstore, key: key, pair: ::Sequel.hstore(key => value))
              else
                @table
                  .where(config.key_column => config.hstore)
                  .exclude(::Sequel[config.value_column].hstore.key?(key))
                  .update(config.value_column => ::Sequel[config.value_column].hstore.merge(key => value))
              end
          end
        end

        def clear(options = {})
          @clear.call(row: config.hstore)
          self
        end

        def values_at(*keys, **options)
          if row = @values_at.call(row: config.hstore, keys: ::Sequel.pg_array(keys))
            row[:values].to_a
          else
            []
          end
        end

        def slice(*keys, **options)
          if row = @slice.call(row: config.hstore, keys: ::Sequel.pg_array(keys))
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
            @store.call(row: config.hstore, pair: ::Sequel.hstore(hash))
          end

          self
        end

        def each_key
          return enum_for(:each_key) { @size.call(row: config.hstore)[:size] } unless block_given?

          ds =
            if config.each_key_server
              @table.server(config.each_key_server)
            else
              @table
            end
          ds = ds.order(:skeys) unless @table.respond_to?(:use_cursor)
          ds.where(config.key_column => config.hstore)
            .select(::Sequel[config.value_column].hstore.skeys)
            .paged_each do |row|
              yield row[:skeys]
            end
          self
        end

        protected

        def create_row
          @create_row.call(row: config.hstore)
        end

        def create_table
          key_column = config.key_column
          value_column = config.value_column

          @backend.create_table?(config.table) do
            column key_column, String, null: false, primary_key: true
            column value_column, :hstore
            index value_column, type: :gin
          end
        end

        def slice_for_update(pairs)
          keys = pairs.map { |k, _| k }.to_a
          if row = @slice_for_update.call(row: config.hstore, keys: ::Sequel.pg_array(keys))
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
            .prepare(:insert, statement_id(:hstore_create_row), config.key_column => :$row, config.value_column => '')
        end

        def prepare_clear
          @clear = @table.where(config.key_column => :$row).prepare(:update, statement_id(:hstore_clear), config.value_column => '')
        end

        def prepare_key
          if defined?(JRUBY_VERSION)
            @key_pl = ::Sequel::Dataset::PlaceholderLiteralizer.loader(@table) do |pl, ds|
              ds.where(config.key_column => config.hstore).select(::Sequel[config.value_column].hstore.key?(pl.arg))
            end
          else
            @key = @table.where(config.key_column => :$row)
              .select(::Sequel[config.value_column].hstore.key?(:$key).as(:present))
              .prepare(:first, statement_id(:hstore_key))
          end
        end

        def prepare_store
          @store = @table
            .where(config.key_column => :$row)
            .prepare(:update, statement_id(:hstore_store), config.value_column => ::Sequel[config.value_column].hstore.merge(:$pair))
        end

        def prepare_increment
          pair = ::Sequel[:hstore]
            .function(:$key, (
              ::Sequel[:coalesce].function(::Sequel[config.value_column].hstore[:$key].cast(Integer), 0) +
              :$amount
            ).cast(String))

          @increment = @table
            .returning(::Sequel[config.value_column].hstore[:$key].as(:value))
            .where(config.key_column => :$row)
            .prepare(:update, statement_id(:hstore_increment), config.value_column => ::Sequel.join([config.value_column, pair]))
        end

        def prepare_load
          @load = @table.where(config.key_column => :$row)
            .select(::Sequel[config.value_column].hstore[:$key].as(:value))
            .prepare(:first, statement_id(:hstore_load))
        end

        def prepare_delete
          @delete = @table.where(config.key_column => :$row)
            .prepare(:update, statement_id(:hstore_delete), config.value_column => ::Sequel[config.value_column].hstore.delete(:$key))
        end

        def prepare_create
          # Under JRuby we can't use a prepared statement for queries involving
          # the hstore `?` (key?) operator.  See
          # https://stackoverflow.com/questions/11940401/escaping-hstore-contains-operators-in-a-jdbc-prepared-statement
          return if defined?(JRUBY_VERSION)
          @create = @table
            .where(config.key_column => :$row)
            .exclude(::Sequel[config.value_column].hstore.key?(:$key))
            .prepare(:update, statement_id(:hstore_create), config.value_column => ::Sequel[config.value_column].hstore.merge(:$pair))
        end

        def prepare_values_at
          @values_at = @table
            .where(config.key_column => :$row)
            .select(::Sequel[config.value_column].hstore[::Sequel.cast(:$keys, :"text[]")].as(:values))
            .prepare(:first, statement_id(:hstore_values_at))
        end

        def prepare_slice
          slice = @table
            .where(config.key_column => :$row)
            .select(::Sequel[config.value_column].hstore.slice(:$keys).as(:pairs))
          @slice = slice.prepare(:first, statement_id(:hstore_slice))
          @slice_for_update = slice.for_update.prepare(:first, statement_id(:hstore_slice_for_update))
        end

        def prepare_size
          @size = @backend
            .from(@table.where(config.key_column => :$row)
            .select(::Sequel[config.value_column].hstore.each))
            .select { count.function.*.as(:size) }
            .prepare(:first, statement_id(:hstore_size))
        end
      end
    end
  end
end
