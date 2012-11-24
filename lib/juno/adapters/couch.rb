require 'couchrest'

module Juno
  module Adapters
    class Couch < Base
      def initialize(options = {})
        @db = ::CouchRest.database!(options[:db])
      end

      def key?(key, options = {})
        !!@db.get(key)
      rescue RestClient::ResourceNotFound
        false
      end

      def load(key, options = {})
        @db.get(key)['data']
      rescue RestClient::ResourceNotFound
        nil
      end

      def store(key, value, options = {})
        if key?(key, options)
          @db.update_doc(key, 'data' => value)
        else
          @db.save_doc('_id' => key, 'data' => value)
        end
        value
      rescue RestClient::RequestFailed
        value
      end

      def delete(key, options = {})
        value = @db.get(key)
        @db.delete_doc('_id' => value['_id'], '_rev' => value['_rev'])
        value['data']
      rescue RestClient::ResourceNotFound
        nil
      end

      def clear(options = {})
        @db.recreate!
        self
      end
    end
  end
end
