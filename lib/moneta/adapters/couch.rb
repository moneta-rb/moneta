begin
  require "couchrest"
rescue LoadError
  puts "You need the couchrest gem to use the CouchDB store"
  exit
end

module Moneta
  module Adapters
    class Couch
      include Defaults

      def initialize(options = {})
        @db = ::CouchRest.database!(options[:db])
      end

      def key?(key, *)
        !self[key_for(key)].nil?
      rescue RestClient::ResourceNotFound
        false
      end

      def [](key)
        deserialize(@db.get(key_for(key))["data"])
      rescue RestClient::ResourceNotFound
        nil
      end

      def store(key, value, *)
        @db.save_doc("_id" => key_for(key), :data => serialize(value))
      rescue RestClient::RequestFailed
        self[key_for(key)]
      end

      def delete(key, *)
        value = @db.get(key_for(key))

        if value
          @db.delete_doc({"_id" => value["_id"], "_rev" => value["_rev"]}) if value
          deserialize(value["data"])
        end
      rescue RestClient::ResourceNotFound
        nil
      end

      def clear(*)
        @db.recreate!
      end
    end
  end
end
