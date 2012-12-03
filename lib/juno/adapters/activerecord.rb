require 'active_record'

module Juno
  module Adapters
    # ActiveRecord as key/value stores
    # @api public
    class ActiveRecord < Base
      def self.tables
        @tables ||= {}
      end

      attr_reader :table

      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :table - Table name (default juno)
      # * :connection - ActiveRecord connection
      def initialize(options = {})
        table = options[:table] || 'juno'
        @table = self.class.tables[table] ||= begin
                                                c = Class.new(::ActiveRecord::Base)
                                                c.table_name = table
                                                c.primary_key = :k
                                                c
                                              end
        @table.establish_connection(options[:connection]) if options[:connection]
        unless @table.table_exists?
          @table.connection.create_table(@table.table_name, :id => false) do |t|
            t.binary :k, :null => false
            t.binary :v
          end
          @table.connection.add_index(@table.table_name, :k, :unique => true)
        end
      end

      def key?(key, options = {})
        !!@table.find_by_k(key)
      end

      def load(key, options = {})
        record = @table.find_by_k(key)
        record ? record.v : nil
      end

      def delete(key, options = {})
        @table.transaction do
          record = @table.find_by_k(key)
          if record
            record.destroy
            record.v
          end
        end
      end

      def store(key, value, options = {})
        @table.transaction do
          record = @table.find_or_initialize_by_k(key)
          record.update_attributes(:v => value)
          value
        end
      end

      def clear(options = {})
        @table.delete_all
        self
      end
    end
  end
end
