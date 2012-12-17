# Copyright: 2011 TMX Credit
# Author: Potapov Sergey (aka Blake)

require 'cassandra'

module Juno
  module Adapters
    # Cassandra backend
    # @api public
    class Cassandra < Base
      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :keyspace - Cassandra keyspace (default Juno)
      # * :column_family - Cassandra column family (default :Juno)
      # * :host - Server host name (default 127.0.0.1)
      # * :port - Server port (default 9160)
      def initialize(options = {})
        options[:keyspace] ||= 'Juno'
        options[:host]     ||= '127.0.0.1'
        options[:port]     ||=  9160
        @column_family = options[:column_family] || :Juno
        @client = ::Cassandra.new(options[:keyspace], "#{options[:host]}:#{options[:port]}")
      end

      def key?(key, options = {})
        @client.exists?(@column_family, key)
      end

      def load(key, options = {})
        value = @client.get(@column_family, key)
        if value
          if options.include?(:expires)
            store(key, value['value'], options)
          else
            value['value']
          end
        end
      end

      def delete(key, options = {})
        if value = load(key, options)
          @client.remove(@column_family, key)
          value
        end
      end

      def store(key, value, options = {})
        @client.insert(@column_family, key,
                       {'value' => value}, :ttl => options[:expires])
        value
      end

      def clear(options = {})
        @client.each_key(@column_family) do |key|
          delete(key)
        end
        self
      end
    end
  end
end
