require 'couchrest'

module Moneta
  module Adapters
    # CouchDB backend
    # @api public
    class Couch
      include Defaults

      # @param [Hash] options
      # @option options [String] :db ('moneta') Couch database
      def initialize(options = {})
        options[:db] ||= 'moneta'
        @db = ::CouchRest.database!(options[:db])
      end

      # @see Proxy#key?
      def key?(key, options = {})
        @db.get(key) != nil
      rescue RestClient::ResourceNotFound
        false
      end

      # @see Proxy#load
      def load(key, options = {})
        @db.get(key)['value']
      rescue RestClient::ResourceNotFound
        nil
      end

      # @see Proxy#store
      def store(key, value, options = {})
        doc = {'_id' => key, 'value' => value}
        begin
          doc['_rev'] = @db.get(key)['_rev']
        rescue RestClient::ResourceNotFound
        end
        @db.save_doc(doc)
        value
      rescue RestClient::RequestFailed
        value
      end

      # @see Proxy#delete
      def delete(key, options = {})
        value = @db.get(key)
        @db.delete_doc('_id' => value['_id'], '_rev' => value['_rev'])
        value['value']
      rescue RestClient::ResourceNotFound
        nil
      end

      # @see Proxy#clear
      def clear(options = {})
        @db.recreate!
        self
      end
    end
  end
end
