require 'sequel'

module Moneta
  module Adapters
    # Sequel backend
    # @api public
    class Sequel
      include Defaults

      # Constructor
      #
      # @param [Hash] options
      # @option options [String] :db Sequel database
      # @option options [String/Symbol] :table (:moneta) Table name
      # @option options All other options passed to `Sequel#connect`
      def initialize(options = {})
        raise ArgumentError, 'Option :db is required' unless db = options.delete(:db)
        table = options.delete(:table) || :moneta
        @db = ::Sequel.connect(db, options)
        @db.create_table?(table) do
          String :k, :null => false, :primary_key => true
          String :v
        end
        @table = @db[table]
      end

      def key?(key, options = {})
        @table[:k => key] != nil
      end

      def load(key, options = {})
        record = @table[:k => key]
        record && record[:v]
      end

      def store(key, value, options = {})
        @db.transaction do
          if key?(key, options)
            @table.update(:k => key, :v => value)
          else
            @table.insert(:k => key, :v => value)
          end
          value
        end
      end

      def increment(key, amount = 1, options = {})
        @db.transaction do
          locked_table = @table.for_update
          if record = locked_table[:k => key]
            value = record[:v]
            intvalue = value.to_i
            raise 'Tried to increment non integer value' unless value == nil || intvalue.to_s == value.to_s
            intvalue += amount
            locked_table.update(:k => key, :v => intvalue.to_s)
            intvalue
          else
            locked_table.insert(:k => key, :v => amount.to_s)
            amount
          end
        end
      end

      def delete(key, options = {})
        @db.transaction do
          if value = load(key, options)
            @table.filter(:k => key).delete
            value
          end
        end
      end

      def clear(options = {})
        @table.delete
        self
      end
    end
  end
end
