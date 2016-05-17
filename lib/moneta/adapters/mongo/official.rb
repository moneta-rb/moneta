require 'moneta/adapters/mongo/base'
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
    #     db = Moneta::Adapters::MongoOfficial.new
    #     db['key'] = {a: 1, b: 2}
    #
    # @api public
    class MongoOfficial < MongoBase
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
      # @option options [::Mongo::Client] :backend Use existing backend instance
      # @option options Other options passed to `Mongo::MongoClient#new`
      def initialize(options = {})
        super(options)
        collection = options.delete(:collection) || 'moneta'
        db = options.delete(:db) || 'moneta'
        @backend = options[:backend] ||
          begin
            host = options.delete(:host) || '127.0.0.1'
            port = options.delete(:port) || DEFAULT_PORT
            options[:logger] ||= ::Logger.new(STDERR).tap do |logger|
              logger.level = ::Logger::ERROR
            end
            ::Mongo::Client.new(["#{host}:#{port}"], options)
          end
        @backend.use(db)
        @collection = @backend[collection]
        if @backend.command(buildinfo: 1).documents.first['version'] >= '2.2'
          @collection.indexes.create_one({@expires_field => 1}, expire_after: 0)
        else
          warn 'Moneta::Adapters::Mongo - You are using MongoDB version < 2.2, expired documents will not be deleted'
        end
      end

      # (see Proxy#load)
      def load(key, options = {})
        key = to_binary(key)
        doc = @collection.find(_id: key).limit(1).first
        if doc && (!doc[@expires_field] || doc[@expires_field] >= Time.now)
          expires = expires_at(options, nil)
          # @expires_field must be a Time object (BSON date datatype)
          @collection.update_one({ _id: key },
                                 '$set' => { @expires_field => expires }) unless expires.nil?
          doc_to_value(doc)
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        key = to_binary(key)
        @collection.replace_one({ _id: key },
                                value_to_doc(key, value, options),
                                upsert: true)
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        key = to_binary(key)
        if doc = @collection.find(_id: key).find_one_and_delete and
          !doc[@expires_field] || doc[@expires_field] >= Time.now
        then
          doc_to_value(doc)
        end
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @collection.find_one_and_update({ _id: to_binary(key) },
                                        { '$inc' => { @value_field => amount } },
                                        :return_document => :after,
                                        :upsert => true)[@value_field]
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        key = to_binary(key)
        @collection.insert_one(value_to_doc(key, value, options))
        true
      rescue ::Mongo::Error::OperationFailure => ex
        raise unless ex.message =~ /^E11000 / # duplicate key error
        false
      end

      # (see Proxy#clear)
      def clear(options = {})
        @collection.delete_many
        self
      end

      # (see Proxy#close)
      def close
        @backend.close
        nil
      end
    end
  end
end
