require 'sqlite3'

module Moneta
  module Adapters
    # Sqlite3 backend
    # @api public
    class Sqlite
      include Defaults
      include IncrementSupport

      supports :create
      attr_reader :backend

      # @param [Hash] options
      # @option options [String] :file Database file
      # @option options [String] :table ('moneta') Table name
      # @option options [Fixnum] :busy_timeout (1000) Sqlite timeout if database is busy
      # @option options [::Sqlite3::Database] :backend Use existing backend instance
      def initialize(options = {})
        table = options[:table] || 'moneta'
        @backend = options[:backend] ||
          begin
            raise ArgumentError, 'Option :file is required' unless options[:file]
            ::SQLite3::Database.new(options[:file])
          end
        @backend.busy_timeout(options[:busy_timeout] || 1000)
        @backend.execute("create table if not exists #{table} (k blob not null primary key, v blob)")
        @stmts =
          [@exists  = @backend.prepare("select exists(select 1 from #{table} where k = ?)"),
           @select  = @backend.prepare("select v from #{table} where k = ?"),
           @replace = @backend.prepare("replace into #{table} values (?, ?)"),
           @delete  = @backend.prepare("delete from #{table} where k = ?"),
           @clear   = @backend.prepare("delete from #{table}"),
           @create  = @backend.prepare("insert into #{table} values (?, ?)")]
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @exists.execute!(key).first.first.to_i == 1
      end

      # (see Proxy#load)
      def load(key, options = {})
        rows = @select.execute!(key)
        rows.empty? ? nil : rows.first.first
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @replace.execute!(key, value)
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = load(key, options)
        @delete.execute!(key)
        value
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @backend.transaction(:exclusive) { return super }
      end

      # (see Proxy#clear)
      def clear(options = {})
        @clear.execute!
        self
      end

      # (see Default#create)
      def create(key, value, options = {})
        @create.execute!(key,value)
        true
      rescue SQLite3::ConstraintException
        # If you know a better way to detect whether an insert-ignore
        # suceeded, please tell me.
        @create.reset!
        false
      end

      # (see Proxy#close)
      def close
        @stmts.each {|s| s.close }
        @backend.close
        nil
      end
    end
  end
end
