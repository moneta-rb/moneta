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

      def key?(key)
        !self[key_for(key)].nil?
      rescue RestClient::ResourceNotFound
        false
      end

      alias has_key? key?

      def [](key)
        @db.get(key_for(key))["data"]
      rescue RestClient::ResourceNotFound
        nil
      end

      def []=(key, value)
        @db.save_doc("_id" => key_for(key), :data => value)
      rescue RestClient::RequestFailed
        self[key_for(key)]
      end

      def delete(key)
        value = @db.get(key_for(key))
        
        if value
          @db.delete_doc({"_id" => value["_id"], "_rev" => value["_rev"]}) if value
          value["data"]
        end
      rescue RestClient::ResourceNotFound
        nil
      end

      def update_key(key, options = {})
        val = self[key]
        self.store(key, val, options)
      rescue RestClient::ResourceNotFound
        nil
      end

      def clear
        @db.recreate!
      end

      def delete_store
        @db.delete!
      end
    end
  end
end
