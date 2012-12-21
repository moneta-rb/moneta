require 'sqlite3'

module Moneta
  module Adapters
    # Sqlite3 backend
    # @api public
    class Sqlite < Base
      include Mixins::IncrementSupport

      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :file - Database file
      # * :table - Table name (default moneta)
      def initialize(options = {})
        raise ArgumentError, 'Option :file is required' unless options[:file]
        table = options[:table] || 'moneta'
        @db = ::SQLite3::Database.new(options[:file])
        @db.execute("create table if not exists #{table} (k blob not null primary key, v blob)")
        @stmts =
          [@select = @db.prepare("select v from #{table} where k = ?"),
           @replace = @db.prepare("replace into #{table} values (?, ?)"),
           @delete = @db.prepare("delete from #{table} where k = ?"),
           @clear = @db.prepare("delete from #{table}")]
      end

      def key?(key, options = {})
        !@select.execute!(key).empty?
      end

      def load(key, options = {})
        rows = @select.execute!(key)
        rows.empty? ? nil : rows.first.first
      end

      def store(key, value, options = {})
        @replace.execute!(key, value)
        value
      end

      def delete(key, options = {})
        value = load(key, options)
        @delete.execute!(key)
        value
      end

      def increment(key, amount = 1, options = {})
        @db.transaction(:exclusive) { return super }
      end

      def clear(options = {})
        @clear.execute!
        self
      end

      def close
        @stmts.each {|s| s.close }
        @db.close
        nil
      end
    end
  end
end
