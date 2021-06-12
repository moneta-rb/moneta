require 'riak'

module Moneta
  module Adapters
    # Riak backend
    # @api public
    # @author Potapov Sergey (aka Blake)
    class Riak < Adapter
      config :bucket, default: 'moneta'
      config :content_type, default: 'application/octet-stream'

      backend { |**options| ::Riak::Client.new(options) }

      # @param [Hash] options
      # @option options [String] :bucket ('moneta') Bucket name
      # @option options [String] :content_type ('application/octet-stream') Default content type
      # @option options [::Riak::Client] :backend Use existing backend instance
      # @option options All other options passed to `Riak::Client#new`
      def initialize(options = {})
        super
        @bucket = backend.bucket(config.bucket)
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @bucket.exists?(key, options.dup)
      end

      # (see Proxy#load)
      def load(key, options = {})
        @bucket.get(key, options.dup).raw_data
      rescue ::Riak::FailedRequest
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
        obj.content_type = options[:content_type] || config.content_type
        obj.raw_data = value
        obj.store(options.dup)
        value
      end

      # (see Proxy#clear)
      def clear(options = {})
        @bucket.keys do |keys|
          keys.each { |key| @bucket.delete(key) }
        end
        self
      end
    end
  end
end
