module Moneta
  module Adapters
    # @api public
    class Sequel
      # @api private
      module Postgres
        def store(key, value, options = {})
          @store.call(key: key, value: blob(value))
          value
        end

        def increment(key, amount = 1, options = {})
          result = @increment.call(key: key, value: blob(amount.to_s), amount: amount)
          if row = result.first
            row[config.value_column].to_i
          end
        end

        def delete(key, options = {})
          result = @delete.call(key: key)
          if row = result.first
            row[config.value_column]
          end
        end

        def merge!(pairs, options = {}, &block)
          @backend.transaction do
            pairs = yield_merge_pairs(pairs, &block) if block_given?
            @table
              .insert_conflict(target: config.key_column,
                               update: { config.value_column => ::Sequel[:excluded][config.value_column] })
              .import([config.key_column, config.value_column], blob_pairs(pairs).to_a)
          end

          self
        end

        def each_key
          return super unless block_given? && !@each_key_server && @table.respond_to?(:use_cursor)
          # With a cursor, this will Just Work.
          @table.select(config.key_column).paged_each do |row|
            yield row[config.key_column]
          end
          self
        end

        protected

        def prepare_store
          @store = @table
            .insert_conflict(target: config.key_column,
                             update: { config.value_column => ::Sequel[:excluded][config.value_column] })
            .prepare(:insert, statement_id(:store), config.key_column => :$key, config.value_column => :$value)
        end

        def prepare_increment
          update_expr = ::Sequel[:convert_to].function(
            (::Sequel[:convert_from].function(
              ::Sequel[config.table][config.value_column],
              'UTF8'
            ).cast(Integer) + :$amount).cast(String),
            'UTF8'
          )

          @increment = @table
            .returning(config.value_column)
            .insert_conflict(target: config.key_column, update: { config.value_column => update_expr })
            .prepare(:insert, statement_id(:increment), config.key_column => :$key, config.value_column => :$value)
        end

        def prepare_delete
          @delete = @table
            .returning(config.value_column)
            .where(config.key_column => :$key)
            .prepare(:delete, statement_id(:delete))
        end
      end
    end
  end
end
