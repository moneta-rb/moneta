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
      # @option options [String] :expires_field ('expiresAt') Document field to store expiration time
      # @option options [String] :value_field ('value') Document field to store value
      # @option options [String] :type_field ('type') Document field to store value type
      # @option options [::Mongo::MongoClient] :backend Use existing backend instance
      # @option options Other options passed to `Mongo::MongoClient#new`
      def initialize(options = {})
        self.default_expires = options.delete(:expires)
        collection = options.delete(:collection) || 'moneta'
        db = options.delete(:db) || 'moneta'
        @expires_field = options.delete(:expires_field) || 'expiresAt'
        @value_field = options.delete(:value_field) || 'value'
        @type_field = options.delete(:type_field) || 'type'
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
          @collection.ensure_index([[@expires_field, ::Mongo::ASCENDING]], :expireAfterSeconds => 0)
        else
          warn 'Moneta::Adapters::Mongo - You are using MongoDB version < 2.2, expired documents will not be deleted'
        end
      end

      # (see Proxy#load)
      def load(key, options = {})
        key = to_binary(key)
        doc = @collection.find_one('_id' => key)
        if doc && (!doc[@expires_field] || doc[@expires_field] >= Time.now)
          expires = expires_at(options, nil)
          @collection.update({ '_id' => key },
                             # @expires_field must be a Time object (BSON date datatype)
                             { '$set' => { @expires_field => expires || nil } }) if expires != nil
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
                                    :update => { '$inc' => { @value_field => amount } },
                                    :new => true,
                                    :upsert => true)[@value_field]
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        key = to_binary(key)
        @collection.insert(value_to_doc(key, value, options))
        true
      rescue ::Mongo::OperationFailure => ex
        raise if ex.error_code != 11000 # duplicate key error
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
        case doc[@type_field]
        when 'Hash'
          doc = doc.dup
          doc.delete('_id')
          doc.delete(@type_field)
          doc.delete(@expires_field)
          doc
        when 'Number'
          doc[@value_field]
        else
          doc[@value_field].to_s
        end
      end

      def value_to_doc(key, value, options)
        case value
        when Hash
          value.merge('_id' => key,
                      @type_field => 'Hash',
                      # @expires_field must be a Time object (BSON date datatype)
                      @expires_field => expires_at(options) || nil)
        when Float, Fixnum
          { '_id' => key,
            @type_field => 'Number',
            @value_field => value,
            # @expires_field must be a Time object (BSON date datatype)
            @expires_field => expires_at(options) || nil }
        when String
          intvalue = value.to_i
          { '_id' => key,
            @type_field => 'String',
            @value_field => intvalue.to_s == value ? intvalue : to_binary(value),
            # @expires_field must be a Time object (BSON date datatype)
            @expires_field => expires_at(options) || nil }
        else
          raise ArgumentError, "Invalid value type: #{value.class}"
        end
      end

      def to_binary(s)
        s = s.dup if s.frozen? # HACK: BSON::Binary needs unfrozen string
        ::BSON::Binary.new(s)
      end
    end
  end
end
