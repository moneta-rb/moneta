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
        cell = @table.get(key, @column).first
        cell && unpack(cell.value)
      end

      def store(key, value, options = {})
        @table.mutate_row(key, @column => pack(value))
        value
      end

      def increment(key, amount = 1, options = {})
        result = @table.atomic_increment(key, @column, amount)
        # HACK: Throw error if applied to invalid value
        if result == 0
          value = load(key)
          raise 'Tried to increment non integer value' unless value.to_s == value.to_i.to_s
        end
        result
      end

      def delete(key, options = {})
        if value = load(key, options)
          @table.delete_row(key)
          unpack(value)
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

      private

      def pack(value)
        intvalue = value.to_i
        if intvalue >= 0 && intvalue <= 0xFFFFFFFFFFFFFFFF && intvalue.to_s == value
          # Pack as 8 byte big endian
          [intvalue].pack('Q>')
        elsif value.bytesize >= 8
          # Add nul character to make value distinguishable from integer
          value << "\0"
        else
          value
        end
      end

      def unpack(value)
        if value.bytesize == 8
          # Unpack 8 byte big endian
          value.unpack('Q>').first.to_s
        elsif value.bytesize >= 9 && value[-1] == ?\0
          # Remove nul character
          value[0..-2]
        else
          value
        end
      end
    end
  end
end
