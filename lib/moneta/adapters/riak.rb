# Copyright: 2011 TMX Credit
# Author: Potapov Sergey (aka Blake)

require 'riak'

module Moneta
  module Adapters
    # Riak backend
    # @api public
    class Riak < Base
      # Constructor
      #
      # @param [Hash] options
      # @option options [String] :bucket ('moneta') Bucket name
      # @option options [String] :content_type ('application/octet-stream') Default content type
      # @option options All other options passed to `Riak::Client#new`
      def initialize(options = {})
        bucket = options.delete(:bucket) || 'moneta'
        @content_type = options.delete(:content_type) || 'application/octet-stream'
        @bucket = ::Riak::Client.new(options).bucket(bucket)
      end

      def key?(key, options = {})
        @bucket.exists?(key, options)
      end

      def load(key, options = {})
        @bucket.get(key, options).raw_data
      rescue ::Riak::FailedRequest => ex
        nil
      end

      def delete(key, options = {})
        value = load(key, options)
        @bucket.delete(key, options)
        value
      end

      def store(key, value, options = {})
        obj = ::Riak::RObject.new(@bucket, key)
        obj.content_type = options[:content_type] || @content_type
        obj.raw_data = value
        obj.store(options)
        value
      end

      def clear(options = {})
        @bucket.keys do |keys|
          keys.each{ |key| @bucket.delete(key) }
        end
        self
      end
    end
  end
end
