require 'mongo'

module Moneta
  module Adapters
    # MongoDB backend
    #
    # Supports expiration, documents will be automatically removed starting
    # with mongodb >= 2.2 (see {http://docs.mongodb.org/manual/tutorial/expire-data/}).
    #
    # You can store hashes directly using this adapter.
    #
    # @example Store hashes
    #     db = Moneta::Adapters::Mongo.new
    #     db['key'] = {a: 1, b: 2}
    #
    # @api public
    class Mongo
      include Defaults
      include ExpiresSupport

      supports :create, :increment
      attr_reader :backend

      # @param [Hash] options
      # @option options [String] :collection ('moneta') MongoDB collection name
      # @option options [String] :host ('127.0.0.1') MongoDB server host
      # @option options [String] :user Username used to authenticate
      # @option options [String] :password Password used to authenticate
      # @option options [Integer] :port (MongoDB default port) MongoDB server port
      # @option options [String] :db ('moneta') MongoDB database
      # @option options [Integer] :expires Default expiration time
      # @option options [::Mongo::MongoClient] :backend Use existing backend instance
      def initialize(options = {})
        self.default_expires = options.delete(:expires)
        collection = options.delete(:collection) || 'moneta'
        db = options.delete(:db) || 'moneta'
        @backend = options[:backend] ||
          begin
            host = options.delete(:host) || '127.0.0.1'
            port = options.delete(:port) || ::Mongo::MongoClient::DEFAULT_PORT
            user = options.delete(:user)
            password = options.delete(:password)
            ::Mongo::MongoClient.new(host, port, options)
          end
        db = @backend.db(db)
        db.authenticate(user, password, true) if user && password
        @collection = db.collection(collection)
        if @backend.server_version >= '2.2'
          @collection.ensure_index([['expiresAt', ::Mongo::ASCENDING]], :expireAfterSeconds => 0)
        else
          warn 'Moneta::Adapters::Mongo - You are using MongoDB version < 2.2, expired documents will not be deleted'
        end
      end

      # (see Proxy#load)
      def load(key, options = {})
        key = to_binary(key)
        doc = @collection.find_one('_id' => key)
        if doc && (!doc['expiresAt'] || doc['expiresAt'] >= Time.now)
          expires = expires_at(options, nil)
          @collection.update({ '_id' => key },
                             # expiresAt must be a Time object (BSON date datatype)
                             { '$set' => { 'expiresAt' => expires || nil } }) if expires != nil
          doc_to_value(doc)
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        key = to_binary(key)
        @collection.update({ '_id' => key },
                           value_to_doc(key, value, options),
                           { :upsert => true })
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = load(key, options)
        @collection.remove('_id' => to_binary(key)) if value
        value
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @collection.find_and_modify(:query => { '_id' => to_binary(key) },
                                    :update => { '$inc' => { 'value' => amount } },
                                    :new => true,
                                    :upsert => true)['value']
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        key = to_binary(key)
        @collection.insert(value_to_doc(key, value, options))
        true
      rescue ::Mongo::OperationFailure
        # FIXME: This catches too many errors
        # it should only catch a not-unique-exception
        false
      end

      # (see Proxy#clear)
      def clear(options = {})
        @collection.remove
        self
      end

      # (see Proxy#close)
      def close
        @backend.close
        nil
      end

      protected

      def doc_to_value(doc)
        case doc['type']
        when 'Hash'
          doc = doc.dup
          doc.delete('_id')
          doc.delete('type')
          doc.delete('expiresAt')
          doc
        when 'Number'
          doc['value']
        else
          doc['value'].to_s
        end
      end

      def value_to_doc(key, value, options)
        case value
        when Hash
          value.merge('_id' => key,
                      'type' => 'Hash',
                      # expiresAt must be a Time object (BSON date datatype)
                      'expiresAt' => expires_at(options) || nil)
        when Float, Fixnum
          { '_id' => key,
            'type' => 'Number',
            'value' => value,
            # expiresAt must be a Time object (BSON date datatype)
            'expiresAt' => expires_at(options) || nil }
        when String
          intvalue = value.to_i
          { '_id' => key,
            'value' => intvalue.to_s == value ? intvalue : to_binary(value),
            # expiresAt must be a Time object (BSON date datatype)
            'expiresAt' => expires_at(options) || nil }
        else
          raise ArgumentError, "Invalid value type: #{value.class}"
        end
      end

      def to_binary(s)
        s = s.dup if s.frozen?
        ::BSON::Binary.new(s)
      end
    end
  end
end
