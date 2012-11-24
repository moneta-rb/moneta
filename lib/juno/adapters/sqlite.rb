require 'sqlite3'

module Juno
  module Adapters
    class Sqlite < Base
      def initialize(options = {})
        raise 'No option :file specified' unless options[:file]
        table = options[:table] || 'juno'
        @db = ::SQLite3::Database.new(options[:file])
        @db.execute("create table if not exists #{table} (key blob primary key, value blob)")
        @select = @db.prepare("select value from #{table} where key = ?")
        @insert = @db.prepare("insert or replace into #{table} values (?, ?)")
        @delete = @db.prepare("delete from #{table} where key = ?")
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
