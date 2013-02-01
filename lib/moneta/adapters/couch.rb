require 'couchrest'

module Moneta
  module Adapters
    # CouchDB backend
    # @api public
    class Couch
      include Defaults

      attr_reader :backend

      # @param [Hash] options
      # @option options [String] :host ('http://127.0.0.1:5984') Couch host
      # @option options [String] :db ('moneta') Couch database
      # @option options [::CouchRest] :backend Use existing backend instance
      def initialize(options = {})
        @backend = options[:backend] || CouchRest.new(options[:host] || '127.0.0.1:5984')
        @db = @backend.database!(options[:db] || 'moneta')
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @db.get(key) != nil
      rescue ::RestClient::ResourceNotFound
        false
      end

      # (see Proxy#load)
      def load(key, options = {})
        @db.get(key)['value']
      rescue ::RestClient::ResourceNotFound
        nil
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        doc = {'_id' => key, 'value' => value}
        begin
          doc['_rev'] = @db.get(key)['_rev']
        rescue ::RestClient::ResourceNotFound
        end
        @db.save_doc(doc)
        value
      rescue ::RestClient::RequestFailed
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = @db.get(key)
        @db.delete_doc('_id' => value['_id'], '_rev' => value['_rev'])
        value['value']
      rescue ::RestClient::ResourceNotFound
        nil
      end

      # (see Proxy#clear)
      def clear(options = {})
        @db.recreate!
        self
      end
    end
  end
end
