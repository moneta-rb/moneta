require 'mongo'

module Moneta
  module Adapters
    # MongoDB backend
    #
    # Supports expiration, documents will be automatically removed starting
    # with mongodb >= 2.2 (see http://docs.mongodb.org/manual/tutorial/expire-data/).
    #
    # @api public
    class Mongo
      include Defaults
      include ExpiresSupport

      # @param [Hash] options
      # @option options [String] :collection ('moneta') MongoDB collection name
      # @option options [String] :host ('127.0.0.1') MongoDB server host
      # @option options [Integer] :port (MongoDB default port) MongoDB server port
      # @option options [String] :db ('moneta') MongoDB database
      # @option options [Integer] :expires Default expiration time
      def initialize(options = {})
        self.default_expires = options.delete(:expires)
        collection = options.delete(:collection) || 'moneta'
        host = options.delete(:host) || '127.0.0.1'
        port = options.delete(:port) || ::Mongo::MongoClient::DEFAULT_PORT
        db = options.delete(:db) || 'moneta'
        connection = ::Mongo::MongoClient.new(host, port, options)
        @collection = connection.db(db).collection(collection)
        if connection.server_version >= '2.2'
          @collection.ensure_index([['expiresAt', ::Mongo::ASCENDING]], :expireAfterSeconds => 0)
        else
          warn 'You are using MongoDB version < 2.2, expired documents will not be deleted'
        end
      end

      # (see Proxy#load)
      def load(key, options = {})
        key = ::BSON::Binary.new(key)
        doc = @collection.find_one('_id' => key)
        if doc && (!doc['expiresAt'] || doc['expiresAt'] >= Time.now)
          # expiresAt must be a Time object (BSON date datatype)
          if !(expires = expiration_time(options[:expires],false)).nil?
            @collection.update({ '_id' => key },
                               { '$set' => {'expiresAt' => expires} })
          end
          doc['value'].to_s
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        # expiresAt must be a Time object (BSON date datatype)
        expiresAt = expiration_time(options[:expires]) || nil
        key = ::BSON::Binary.new(key)
        intvalue = value.to_i
        @collection.update({ '_id' => key },
                           { '_id' => key,
                             'value' => intvalue.to_s == value ? intvalue : ::BSON::Binary.new(value),
                             'expiresAt' => expiresAt },
                           { :upsert => true })
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = load(key, options)
        @collection.remove('_id' => ::BSON::Binary.new(key)) if value
        value
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @collection.find_and_modify(:query => { '_id' => ::BSON::Binary.new(key) },
                                    :update => { '$inc' => { 'value' => amount } },
                                    :new => true,
                                    :upsert => true)['value']
      end

      # (see Proxy#clear)
      def clear(options = {})
        @collection.remove
        self
      end

    end
  end
end
