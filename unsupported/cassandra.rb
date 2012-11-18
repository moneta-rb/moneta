# Copyright: 2011 TMX Credit
# Author: Potapov Sergey (aka Blake)

require 'cassandra'

module Juno
  class Cassandra < Base
    def initialize(options = {})
      options[:keyspace] ||= 'Juno'
      options[:host]     ||= '127.0.0.1'
      options[:port]     ||=  9160
      @client = ::Cassandra.new(options[:keyspace], "#{options[:host]}:#{options[:port]}")
      @column_family = options[:column_family] || :Juno
    end

    def key?(key, options = {})
      key = key_for(key)
      @client.exists?(@column_family, key)
    end

    def [](key)
      key = key_for(key)
      deserialize(@client.get(@column_family, key)['value'])
    end

    def delete(key, options = {})
      key = key_for(key)
      value = self[key]
      @client.remove(@column_family, key)
      value
    end

    def store(key, value, options = {})
      key = key_for(key)
      @client.insert(@column_family, key, {'value' => serialize(value)})
    end

    def clear(options = {})
      @client.each_key(@column_family) do |key|
        delete(key)
      end
      nil
    end
  end
end
