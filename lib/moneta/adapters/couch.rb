require 'faraday'
require 'multi_json'

module Moneta
  module Adapters
    # CouchDB backend
    # @api public
    class Couch
      include Defaults

      attr_reader :backend

      # @param [Hash] options
      # @option options [String] :host ('127.0.0.1') Couch host
      # @option options [String] :port (5984) Couch port
      # @option options [String] :db ('moneta') Couch database
      # @option options [Faraday connection] :backend Use existing backend instance
      def initialize(options = {})
        url = "http://#{options[:host] || '127.0.0.1'}:#{options[:port] || 5984}/#{options[:db] || 'moneta'}"
        @backend = options[:backend] || ::Faraday.new(:url => url)
        create_db
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @backend.head(key).status == 200
      end

      # (see Proxy#load)
      def load(key, options = {})
        response = @backend.get(key)
        response.status == 200 ? MultiJson.load(response.body)['value'] : nil
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        response = @backend.head(key)
        doc = { 'value' => value }
        doc['_rev'] = response['etag'][1..-2] if response.status == 200
        response = @backend.put(key, MultiJson.dump(doc), 'Content-Type' => 'application/json')
        raise "HTTP error #{response.status}" unless response.status == 201
        value
      rescue
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        response = @backend.get(key)
        if response.status == 200
          value = MultiJson.load(response.body)['value']
          response = @backend.delete("#{key}?rev=#{response['etag'][1..-2]}")
          raise "HTTP error #{response.status}" unless response.status == 200
          value
        end
      rescue
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#clear)
      def clear(options = {})
        @backend.delete ''
        create_db
        self
      end

      private

      def create_db
        response = @backend.put '', ''
        raise "HTTP error #{response.status}" unless response.status == 201 || response.status == 412
      end
    end
  end
end
