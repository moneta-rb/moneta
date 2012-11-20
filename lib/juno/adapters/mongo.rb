require 'mongo'

module Juno
  module Adapters
    class Mongo < Base
      def initialize(options = {})
        collection = options.delete(:collection) || 'juno'
        host = options.delete(:host) || 'localhost'
        port = options.delete(:port) || ::Mongo::Connection::DEFAULT_PORT
        db = options.delete(:db) || 'juno'
        connection = ::Mongo::Connection.new(host, port, options)
        @collection = connection.db(db).collection(collection)
      end

      def key?(key, options = {})
        !!load(key, options)
      end

      def load(key, options = {})
        value = @collection.find_one('_id' => key)
        value ? value['data'] : nil
      end

      def delete(key, options = {})
        value = load(key, options)
        @collection.remove('_id' => key) if value
        value
      end

      def store(key, value, options = {})
        @collection.update({ '_id' => key },
                      { '_id' => key, 'data' => value },
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
