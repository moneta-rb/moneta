# Copyright: 2011 TMX Credit
# Author: Potapov Sergey (aka Blake)

require 'ripple'

module Juno
  class Riak < Base
    def initialize(options = {})
      bucket_name = options.delete(:bucket) || 'juno'
      client = ::Riak::Client.new(options)
      @bucket = client.bucket(bucket_name)
    end

    def key?(key, options = {})
      !!self[key]
    end

    def load(key, options = {})
      deserialize(@bucket[key_for(key)].data)
    rescue ::Riak::HTTPFailedRequest => err
      nil
    end

    def delete(key, options = {})
      value = self[key]
      @bucket.delete(key_for(key))
      value
    end

    def store(key, value, options = {})
      obj = ::Riak::RObject.new(@bucket, key_for(key))
      obj.content_type = 'text/plain'
      obj.data = serialize(value)
      obj.store
      value
    end

    def clear(options = {})
      @bucket.keys(:reload => true) do |keys|
        keys.each{|key| @bucket.delete(key) }
      end
      nil
    end
  end
end
