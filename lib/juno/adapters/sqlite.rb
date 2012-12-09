require 'sqlite3'

module Juno
  module Adapters
    # Sqlite3 backend
    # @api public
    class Sqlite < Base
      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :file - Database file
      # * :table - Table name (default juno)
      def initialize(options = {})
        raise 'Option :file is required' unless options[:file]
        table = options[:table] || 'juno'
        @db = ::SQLite3::Database.new(options[:file])
        @db.execute("create table if not exists #{table} (k blob not null primary key, v blob)")
        @select = @db.prepare("select v from #{table} where k = ?")
        @insert = @db.prepare("insert or replace into #{table} values (?, ?)")
        @delete = @db.prepare("delete from #{table} where k = ?")
        @clear = @db.prepare("delete from #{table}")
      end

      def key?(key, options = {})
        !@select.execute!(key).empty?
      end

      def load(key, options = {})
        rows = @select.execute!(key)
        rows.empty? ? nil : rows.first.first
      end

      def store(key, value, options = {})
        @insert.execute!(key, value)
        value
      end

      def delete(key, options = {})
        value = load(key, options)
        @delete.execute!(key)
        value
      end

      def clear(options = {})
        @clear.execute!
        self
      end

      def close
        @select.close
        @insert.close
        @delete.close
        @clear.close
        @db.close
        nil
      end
    end
  end
end
