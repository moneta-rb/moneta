require 'hbaserb'

module Moneta
  module Adapters
    # HBase thrift backend
    # @api public
    class HBase < Base
      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :host - Server host name (default 127.0.0.1)
      # * :port - Server port (default 9090)
      # * :table - Table name (default moneta)
      # * :column_family - Column family (default moneta)
      # * :column - Column (default value)
      def initialize(options = {})
        options[:host] ||= '127.0.0.1'
        options[:port] ||= '9090'
        options[:table] ||= 'moneta'
        options[:column] ||= 'value'
        cf = (options[:column_family] || 'moneta')
        @db = HBaseRb::Client.new(options[:host], options[:port])
        @db.create_table(options[:table], cf) unless @db.has_table?(options[:table])
        @table = @db.get_table(options[:table])
        @column = "#{cf}:#{options[:column]}"
      end

      def key?(key, options = {})
        @table.get(key, @column).first != nil
      end

      def load(key, options = {})
        value = @table.get(key, @column).first
        value && value.value
      end

      def store(key, value, options = {})
        @table.mutate_row(key, @column => value)
        value
      end

      def increment(key, amount = 1, options = {})
        @table.atomic_increment(key, @column, amount)
      end

      def delete(key, options = {})
        if value = load(key, options)
          @table.delete_row(key)
          value
        end
      end

      def clear(options = {})
        @table.create_scanner do |row|
          @table.delete_row(row.row)
        end
        self
      end

      def close
        @db.close
        nil
      end
    end
  end
end
