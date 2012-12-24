require 'mongo'

module Moneta
  module Adapters
    # MongoDB backend
    # @api public
    class Mongo < Base
      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :collection - MongoDB collection name (default moneta)
      # * :host - MongoDB server host (default localhost)
      # * :port - MongoDB server port (default mongodb default port)
      # * :db - MongoDB database (default moneta)
      def initialize(options = {})
        collection = options.delete(:collection) || 'moneta'
        host = options.delete(:host) || 'localhost'
        port = options.delete(:port) || ::Mongo::Connection::DEFAULT_PORT
        db = options.delete(:db) || 'moneta'
        connection = ::Mongo::Connection.new(host, port, options)
        @collection = connection.db(db).collection(collection)
      end

      def load(key, options = {})
        value = @collection.find_one('_id' => ::BSON::Binary.new(key))
        value && value['value'].to_s
      end

      def delete(key, options = {})
        value = load(key, options)
        @collection.remove('_id' => ::BSON::Binary.new(key)) if value
        value
      end

      def store(key, value, options = {})
        key = ::BSON::Binary.new(key)
        @collection.update({ '_id' => key },
                           { '_id' => key, 'value' => ::BSON::Binary.new(value) },
                           { :upsert => true })
        value
      end

      def clear(options = {})
        @collection.remove
        self
      end
    end
  end
end
