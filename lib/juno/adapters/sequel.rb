require 'sequel'

module Juno
  module Adapters
    class Sequel < Base
      def initialize(options = {})
        raise 'No option :db specified' unless db = options.delete(:db)
        @table = options.delete(:table) || :juno
        @db = ::Sequel.connect(db, options)
        @db.create_table?(@table) do
          primary_key :k
          String :k
          String :v
        end
      end

      def key?(key, options = {})
        !!sequel_table[:k => key]
      end

      def load(key, options = {})
        result = sequel_table[:k => key]
        result ? result[:v] : nil
      end

      def store(key, value, options = {})
        sequel_table.insert(:k => key, :v => value)
        value
      end

      def delete(key, options = {})
        if value = load(key, options)
          sequel_table.filter(:k => key).delete
          value
        end
      end

      def clear(options = {})
        sequel_table.delete
        self
      end

      private

      def sequel_table
        @sequel_table ||= @db[@table]
      end
    end
  end
end
