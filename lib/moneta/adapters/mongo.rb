require 'mongo'

module Moneta
  module Adapters
    # MongoDB backend
    # @api public
    class Mongo
      include Defaults

      # @param [Hash] options
      # @option options [String] :collection ('moneta') MongoDB collection name
      # @option options [String] :host ('127.0.0.1') MongoDB server host
      # @option options [Integer] :port (MongoDB default port) MongoDB server port
      # @option options [String] :db ('moneta') MongoDB database
      def initialize(options = {})
        collection = options.delete(:collection) || 'moneta'
        host = options.delete(:host) || '127.0.0.1'
        port = options.delete(:port) || ::Mongo::Connection::DEFAULT_PORT
        db = options.delete(:db) || 'moneta'
        connection = ::Mongo::Connection.new(host, port, options)
        @collection = connection.db(db).collection(collection)
      end

      # (see Proxy#load)
      def load(key, options = {})
        value = @collection.find_one('_id' => ::BSON::Binary.new(key))
        value && value['value'].to_s
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = load(key, options)
        @collection.remove('_id' => ::BSON::Binary.new(key)) if value
        value
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        key = ::BSON::Binary.new(key)
        @collection.update({ '_id' => key },
                           { '_id' => key, 'value' => ::BSON::Binary.new(value) },
                           { :upsert => true })
        value
      end

      # (see Proxy#clear)
      def clear(options = {})
        @collection.remove
        self
      end
    end
  end
end
