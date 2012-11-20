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
        @table.connection.create_table @table.table_name do |t|
          t.binary 'key', :primary => true
          t.binary 'value'
        end unless @table.table_exists?
      end

      def key?(key, options = {})
        !!@table.find_by_key(key)
      end

      def load(key, options = {})
        record = @table.find_by_key(key)
        record ? record.value : nil
      end

      def delete(key, options = {})
        record = @table.find_by_key(key)
        if record
          value = record.value
          record.destroy
          value
        end
      end

      def store(key, value, options = {})
        record = @table.find_by_key(key)
        record ||= @table.new(:key => key)
        record.value = value
        record.save!
        value
      end

      def clear(options = {})
        @table.delete_all
        self
      end
    end
  end
end
