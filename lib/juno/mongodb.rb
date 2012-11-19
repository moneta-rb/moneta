require 'mongo'

module Juno
  class MongoDB < Base
    def initialize(options = {})
      collection = options.delete(:collection) || 'juno'
      host = options.delete(:host) || 'localhost'
      port = options.delete(:port) || Mongo::Connection::DEFAULT_PORT
      db = options.delete(:db) || 'juno'
      connection = Mongo::Connection.new(host, port, options)
      @store = connection.db(db).collection(collection)
    end

    def key?(key, options = {})
      !!load(key, options)
    end

    def load(key, options = {})
      value = @store.find_one('_id' => key_for(key))
      value ? deserialize(value['data']) : nil
    end

    def delete(key, options = {})
      value = load(key, options)
      @store.remove('_id' => key_for(key)) if value
      value
    end

    def store(key, value, options = {})
      key = key_for(key)
      @store.update({ '_id' => key },
                    { '_id' => key, 'data' => serialize(value) },
                    { :upsert => true })
      value
    end

    def clear(options = {})
      @store.remove
      nil
    end
  end
end
