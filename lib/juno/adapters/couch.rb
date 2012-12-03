require 'couchrest'

module Juno
  module Adapters
    # CouchDB backend
    # @api public
    class Couch < Base
      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :db - Couch database
      def initialize(options = {})
        raise 'No option :db specified' unless options[:db]
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
        doc = {'_id' => key, 'data' => value}
        begin
          doc['_rev'] = @db.get(key)['_rev']
        rescue RestClient::ResourceNotFound
        end
        @db.save_doc(doc)
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
