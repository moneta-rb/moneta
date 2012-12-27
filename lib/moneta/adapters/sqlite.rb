require 'sqlite3'

module Moneta
  module Adapters
    # Sqlite3 backend
    # @api public
    class Sqlite
      include Defaults
      include IncrementSupport

      # @param [Hash] options
      # @option options [String] :file Database file
      # @option options [String] :table ('moneta') Table name
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

      # @see Proxy#key?
      def key?(key, options = {})
        !@select.execute!(key).empty?
      end

      # @see Proxy#load
      def load(key, options = {})
        rows = @select.execute!(key)
        rows.empty? ? nil : rows.first.first
      end

      # @see Proxy#store
      def store(key, value, options = {})
        @replace.execute!(key, value)
        value
      end

      # @see Proxy#delete
      def delete(key, options = {})
        value = load(key, options)
        @delete.execute!(key)
        value
      end

      # @see Proxy#increment
      def increment(key, amount = 1, options = {})
        @db.transaction(:exclusive) { return super }
      end

      # @see Proxy#clear
      def clear(options = {})
        @clear.execute!
        self
      end

      # @see Proxy#close
      def close
        @stmts.each {|s| s.close }
        @db.close
        nil
      end
    end
  end
end
