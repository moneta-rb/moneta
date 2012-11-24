require 'active_record'

module Juno
  module Adapters
    class ActiveRecord < Base
      def self.tables
        @tables ||= {}
      end

      attr_reader :table

      def initialize(options = {})
        table = options[:table] || 'juno'
        @table = self.class.tables[table] ||= begin
                                                c = Class.new(::ActiveRecord::Base)
                                                c.table_name = table
                                                c
                                              end
        @table.establish_connection(options[:connection]) if options[:connection]
        unless @table.table_exists?
          @table.connection.create_table(@table.table_name) do |t|
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
            value = record.v
            record.destroy
            value
          end
        end
      end

      def store(key, value, options = {})
        @table.transaction do
          record = @table.find_by_k(key)
          record ||= @table.new(:k => key)
          record.v = value
          record.save!
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
