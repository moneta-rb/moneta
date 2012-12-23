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
        !@table.where(:k => key).empty?
      end

      def load(key, options = {})
        record = @table.select(:v).where(:k => key).first
        record && record.v
      end

      def store(key, value, options = {})
        record = @table.select(:k).where(:k => key).first_or_initialize
        record.v = value
        record.save
        value
      end

      def delete(key, options = {})
        if record = @table.where(:k => key).first
          record.destroy
          record.v
        end
      end

      def increment(key, amount = 1, options = {})
        record = @table.where(:k => key).lock.first_or_initialize
        value = record.v
        intvalue = value.to_i
        raise 'Tried to increment non integer value' unless value == nil || intvalue.to_s == value.to_s
        intvalue += amount
        record.v = intvalue.to_s
        record.save
        intvalue
      end

      def clear(options = {})
        @table.delete_all
        self
      end
    end
  end
end
