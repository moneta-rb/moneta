require 'sequel'

module Moneta
  module Adapters
    # Sequel backend
    # @api public
    class Sequel < Base
      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :db - Sequel database
      # * :table - Table name (default :moneta)
      # * All other options passed to Sequel#connect
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
        result = @table[:k => key]
        result && result[:v]
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
