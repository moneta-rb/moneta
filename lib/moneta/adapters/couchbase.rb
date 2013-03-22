require 'couchbase'

module Moneta
  module Adapters
    # CouchBase backend
    # @api public
    class CouchBase
      include Defaults
      include ExpiresSupport

      supports :create, :increment
      attr_reader :backend

      # @param [Hash] options
      # @option options [String] :hostname ('localhost') Couchbase host
      # @option options [String] :port (8091) Couchbase port
      # @option options [String] :pool ('default') Couchbase cluster
      # @option options [String] :bucket ('default') Couchbase database
      # @option options [Couchbase::Bucket] :backend Use existing backend instance
      def initialize(options = {})
      	self.default_expires = options.delete(:expires)
        @backend = options[:backend] || Couchbase.connect(options[:url] || options)
      end

      # (see Proxy#load)
      def load(key, options = {})
        value = @backend.get(key, :quiet => true)
        if value
          update_expires(key, options)
          value
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
      	expires = expires_value(options)
        @backend.set(key, value, :ttl => expires)
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
      	value = @backend.get(key, :quiet => false)
      	@backend.delete(key, :quiet => true)
      	value
      rescue ::Couchbase::Error::NotFound
      end
      
      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        value = @backend.incr(key, amount)
        update_expires(key, options)
        value
      end
      
      # (see Defaults#create)
      def create(key, value, options = {})
      	expires = expires_value(options)
        @backend.add(key, value, :ttl => expires)
        true
      rescue ::Couchbase::Error::KeyExists
      	false
      end
      
      protected
      
      def update_expires(key, options, default = @default_expires)
        expires = expires_value(options, default)
        @backend.touch(key => expires) if expires != nil
      end
    end
  end
end
