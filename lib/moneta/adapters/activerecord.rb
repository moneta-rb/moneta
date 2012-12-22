require 'active_record'

module Moneta
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
      # * :table - Table name (default moneta)
      # * :connection - ActiveRecord connection
      def initialize(options = {})
        table = options[:table] || 'moneta'
        @table = self.class.tables[table] ||=
          begin
            c = Class.new(::ActiveRecord::Base)
            c.table_name = table
            c.primary_key = :k
            c
          end
        @table.establish_connection(options[:connection]) if options[:connection]
        unless @table.table_exists?
          @table.connection.create_table(@table.table_name, :id => false) do |t|
            # Do not use binary columns (Issue #17)
            t.string :k, :null => false
            t.string :v
          end
          @table.connection.add_index(@table.table_name, :k, :unique => true)
        end
      end

      def key?(key, options = {})
        @table.find_by_k(key) != nil
      end

      def load(key, options = {})
        record = @table.find_by_k(key)
        record && record.v
      end

      def store(key, value, options = {})
        @table.transaction do
          record = @table.find_or_initialize_by_k(key)
          record.update_attributes(:v => value)
          value
        end
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

      def increment(key, amount = 1, options = {})
        @table.transaction do
          record = @table.find_or_initialize_by_k(key)
          record.lock!
          value = record.v
          intvalue = value.to_i
          raise 'Tried to increment non integer value' unless value == nil || intvalue.to_s == value.to_s
          intvalue += amount
          record.v = intvalue.to_s
          record.save!
          intvalue
        end
      end

      def clear(options = {})
        @table.delete_all
        self
      end
    end
  end
end
