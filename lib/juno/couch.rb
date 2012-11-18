require 'couchrest'

module Juno
  class Couch < Base
    def initialize(options = {})
      @db = ::CouchRest.database!(options[:db])
    end

    def key?(key, options = {})
      !!self[key_for(key)]
    rescue RestClient::ResourceNotFound
      false
    end

    def [](key)
      deserialize(@db.get(key_for(key))['data'])
    rescue RestClient::ResourceNotFound
      nil
    end

    def store(key, value, options = {})
      @db.save_doc('_id' => key_for(key), :data => serialize(value))
      value
    rescue RestClient::RequestFailed
      value
    end

    def delete(key, options = {})
      value = @db.get(key_for(key))
      if value
        @db.delete_doc({'_id' => value['_id'], '_rev' => value['_rev']}) if value
        deserialize(value['data'])
      end
    rescue RestClient::ResourceNotFound
      nil
    end

    def clear(options = {})
      @db.recreate!
      nil
    end
  end
end
