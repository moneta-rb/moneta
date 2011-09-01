# Copyright: 2011 TMX Credit
# Author: Potapov Sergey (aka Blake)

begin
  require "ripple"
rescue LoadError
  puts "You need the ripple gem to use the Riak store"
  exit
end

module Moneta
  module Adapters
    class Riak
      include Defaults
      
      def initialize(options = {})
        bucket_name = options.delete(:bucket) || 'moneta'
        client = ::Riak::Client.new(options)
        @bucket = client.bucket(bucket_name)
      end

      def key?(key, *)
        !!self[key]
      end

      def [](key)
        serialized_key = key_for(key)
        deserialize(@bucket[serialized_key].data)
      rescue ::Riak::HTTPFailedRequest => err
        nil
      end

      def delete(key, *)
        value = self[key]
        serialized_key = key_for(key)
        @bucket.delete(serialized_key)
        value
      end

      def store(key, value, *)
        serialized_key = key_for(key)
        obj = ::Riak::RObject.new(@bucket, serialized_key)
        obj.content_type = "text/plain"
        obj.data = serialize(value)
        obj.store
      end

      def clear(*)
        @bucket.keys.each{|key| @bucket.delete(key)}
      end
    end
  end
end
