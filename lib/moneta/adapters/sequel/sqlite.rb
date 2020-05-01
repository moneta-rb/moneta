module Moneta
  module Adapters
    class Sequel
      # @api private
      module SQLite
        def self.extended(mod)
          version = mod.backend.get(::Sequel[:sqlite_version].function)
          # See https://sqlite.org/lang_UPSERT.html
          mod.instance_variable_set(:@can_upsert, ::Gem::Version.new(version) >= ::Gem::Version.new('3.24.0'))
        end

        def store(key, value, options = {})
          @table.insert_conflict(:replace).insert(key_column => key, value_column => blob(value))
          value
        end

        def increment(key, amount = 1, options = {})
          return super unless @can_upsert
          @backend.transaction do
            @increment.call(key: key, value: blob(amount.to_s), amount: amount)
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
              update_where: ::Sequel.|({ value_column => blob("0") },
                                       { ::Sequel.~(::Sequel[value_column].cast(Integer)) => 0 })
            )
            .prepare(:insert, statement_id(:increment), key_column => :$key, value_column => :$value)
        end
      end
    end
  end
end
