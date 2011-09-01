# Copyright: 2011 TMX Credit
# Author: Potapov Sergey (aka Blake)

begin
  require "cassandra"
rescue LoadError
  puts "You need the cassandra gem to use the Cassandra store"
  exit
end

module Moneta
  module Adapters
    class Cassandra
      include Defaults
      
      def initialize(options = {})
        options[:keyspace] ||= 'Moneta'
        options[:host]     ||= '127.0.0.1'
        options[:port]     ||=  9160
        @client = ::Cassandra.new(options[:keyspace], "#{options[:host]}:#{options[:port]}")
        @column_family = options[:column_family] || :Moneta
      end

      def key?(key, *)
        key = key_for(key)
        @client.exists?(@column_family, key)
      end

      def [](key)
        key = key_for(key)
        deserialize(@client.get(@column_family, key)['value'])
      end

      def delete(key, *)
        key = key_for(key)
        value = self[key]
        @client.remove(@column_family, key)
        value
      end

      def store(key, value, *)
        key = key_for(key)
        @client.insert(@column_family, key, {'value' => serialize(value)})
      end

      def clear(*)
        @client.each_key(@column_family) do |key|
          delete(key)
        end
      end
    end
  end
end
