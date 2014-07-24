require 'mysql2'

module Moneta
  module Adapters
    # MySQL backend
    # @api public
    class Mysql
      include Defaults
      include IncrementSupport

      supports :create
      attr_reader :backend

      # @param [Hash] options
      # @option options [String] :table ('moneta') Table name
      # @option options [::Mysql2::Client] :backend Use existing backend instance
      # @option options Other options passed to `Mysql2::Client#new`
      def initialize(options = {})
        @table = options.delete(:table) || 'moneta'
        @backend = options[:backend] || ::Mysql2::Client.new(options)

        if table_exists?
          columns       = @backend.query("SHOW COLUMNS FROM #{@table}", :as=>:hash).to_a
          @key_column   = columns.detect{|h|h['Key']=='PRI'}['Field']
          @value_column = columns.detect{|h|h['Key']!='PRI'}['Field']
        else
          @key_column   = 'k'
          @value_column = 'v'
          create_table!
        end
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @backend.query("SELECT #{value_column} FROM #{@table} WHERE #{key_column} = '#{@backend.escape key}'", :cast => false).any?
      end

      # (see Proxy#load)
      def load(key, options = {})
        rows = @backend.query("SELECT #{value_column} FROM #{@table} WHERE #{key_column} = '#{@backend.escape key}' LIMIT 1", :as=>:array, :cast => false)
        rows.first.first if rows.any?
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @backend.query("REPLACE INTO #{@table} SET #{value_column} = '#{@backend.escape value}' WHERE #{key_column} = '#{@backend.escape key}'")
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = load(key, options)
        @backend.query("DELETE FROM #{@table} WHERE #{key_column} = '#{@backend.escape key}'")
        value
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        # @backend.transaction(:exclusive) { return super }
      end

      # (see Proxy#clear)
      def clear(options = {})
        @backend.query("TRUNCATE #{@table}")
        self
      end

      # (see Default#create)
      def create(key, value, options = {})
        @backend.query("INSERT INTO #{@table} SET #{value_column} = '#{@backend.escape value}' WHERE #{key_column} = '#{@backend.escape key}' ON DUPLICATE KEY UPDATE ")
        value
      end

      # (see Proxy#close)
      def close
        @backend.close
        nil
      end

    private
      def create_table!
        # InnoDB has a max key length of 767. Seems like a good default
        @backend.query("CREATE TABLE IF NOT EXISTS #{@table} (#{@key_column} VARBINARY(767) NOT NULL PRIMARY KEY, #{@value_column} BLOB)")
      end

      def table_exists?
        @backend.query("SHOW TABLES LIKE '#{@table}'").any?
      end
    end
  end
end



