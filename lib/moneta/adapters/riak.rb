require 'riak'

module Moneta
  module Adapters
    # Riak backend
    # @api public
    # @author Potapov Sergey (aka Blake)
    class Riak
      include Defaults

      attr_reader :backend

      # @param [Hash] options
      # @option options [String] :bucket ('moneta') Bucket name
      # @option options [String] :content_type ('application/octet-stream') Default content type
      # @option options All other options passed to `Riak::Client#new`
      # @option options [::Riak::Client] :backend Use existing backend instance
      def initialize(options = {})
        bucket = options.delete(:bucket) || 'moneta'
        @content_type = options.delete(:content_type) || 'application/octet-stream'
        @backend = options[:backend] || ::Riak::Client.new(options)
        @bucket = @backend.bucket(bucket)
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @bucket.exists?(key, options.dup)
      end

      # (see Proxy#load)
      def load(key, options = {})
        @bucket.get(key, options.dup).raw_data
      rescue ::Riak::FailedRequest => ex
        nil
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = load(key, options)
        @bucket.delete(key, options.dup)
        value
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        obj = ::Riak::RObject.new(@bucket, key)
        obj.content_type = options[:content_type] || @content_type
        obj.raw_data = value
        obj.store(options.dup)
        value
      end

      # (see Proxy#clear)
      def clear(options = {})
        @bucket.keys do |keys|
          keys.each{ |key| @bucket.delete(key) }
        end
        self
      end
    end
  end
end
