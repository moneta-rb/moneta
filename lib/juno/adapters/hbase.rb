require 'hbaserb'

module Juno
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
      # * :table - Table name (default juno)
      # * :column_family - Column family (default juno)
      # * :column - Column (default value)
      def initialize(options = {})
        options[:host] ||= '127.0.0.1'
        options[:port] ||= '9090'
        options[:table] ||= 'juno'
        options[:column] ||= 'value'
        cf = (options[:column_family] || 'juno')
        @db = HBaseRb::Client.new(options[:host], options[:port])
        @db.create_table(options[:table], cf) unless @db.has_table?(options[:table])
        @table = @db.get_table(options[:table])
        @column = "#{cf}:#{options[:column]}"
      end

      def key?(key, options = {})
        !!@table.get(key, @column).first
      end

      def load(key, options = {})
        value = @table.get(key, @column).first
        value ? value.value : nil
      end

      def delete(key, options = {})
        if value = load(key, options)
          @table.delete_row(key)
          value
        end
      end

      def store(key, value, options = {})
        @table.mutate_row(key, @column => value)
        value
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
