# Copyright: 2011 TMX Credit
# Author: Potapov Sergey (aka Blake)

require 'cassandra'

module Juno
  module Adapters
    class Cassandra < Base
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
        value ? value['value'] : nil
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
