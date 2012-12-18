require 'mongo'

module Juno
  module Adapters
    # MongoDB backend
    # @api public
    class Mongo < Base
      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :collection - MongoDB collection name (default juno)
      # * :host - MongoDB server host (default localhost)
      # * :port - MongoDB server port (default mongodb default port)
      # * :db - MongoDB database (default juno)
      def initialize(options = {})
        collection = options.delete(:collection) || 'juno'
        host = options.delete(:host) || 'localhost'
        port = options.delete(:port) || ::Mongo::Connection::DEFAULT_PORT
        db = options.delete(:db) || 'juno'
        connection = ::Mongo::Connection.new(host, port, options)
        @collection = connection.db(db).collection(collection)
      end

      def load(key, options = {})
        value = @collection.find_one('_id' => key)
        value ? value['value'].to_s : nil
      end

      def delete(key, options = {})
        value = load(key, options)
        @collection.remove('_id' => key) if value
        value
      end

      def store(key, value, options = {})
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
