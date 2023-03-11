module Moneta
  module Adapters
    class Sequel
      # @api private
      module MySQL
        def store(key, value, options = {})
          @store.call(key: key, value: blob(value))
          value
        end

        def increment(key, amount = 1, options = {})
          @backend.transaction(retry_on: [::Sequel::SerializationFailure]) do
            @increment.call(key: key, amount: amount)
            Integer(load(key))
          end
        end

        def merge!(pairs, options = {}, &block)
          @backend.transaction do
            pairs = yield_merge_pairs(pairs, &block) if block_given?
            @table
              .on_duplicate_key_update
              .import([config.key_column, config.value_column], blob_pairs(pairs).to_a)
          end

          self
        end

        def each_key
          return super unless block_given? && config.each_key_server && @table.respond_to?(:stream)
          # Order is not required when streaming
          @table.server(config.each_key_server).select(config.key_column).paged_each do |row|
            yield row[config.key_column]
          end
          self
        end

        protected

        def prepare_store
          @store = @table
            .on_duplicate_key_update
            .prepare(:insert, statement_id(:store), config.key_column => :$key, config.value_column => :$value)
        end

        def prepare_increment
          @increment = @table
            .on_duplicate_key_update(config.value_column => ::Sequel.cast(config.value_column, Integer) + :$amount)
            .prepare(:insert, statement_id(:increment_insert), config.key_column => :$key, config.value_column => :$amount)
        end
      end
    end
  end
end
