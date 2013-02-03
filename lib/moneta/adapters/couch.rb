require 'net/http'
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
      # @option options [::CouchRest] :backend Use existing backend instance
      def initialize(options = {})
        @backend = options[:backend] || ::Net::HTTP.start(options[:host] || '127.0.0.1',
                                                          options[:port] || 5984)
        @path = "/#{options[:db] || 'moneta'}/"
        create_db
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        response = @backend.request_head(@path + key)
        response.code == '200'
      end

      # (see Proxy#load)
      def load(key, options = {})
        response = @backend.request_get(@path + key)
        response.code == '200' ? MultiJson.load(response.body)['value'] : nil
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        response = @backend.request_head(@path + key)
        doc = { 'value' => value }
        doc['_rev'] = response['etag'][1..-2] if response.code == '200'
        response = @backend.request_put(@path + key, MultiJson.dump(doc), 'Content-Type' => 'application/json')
        raise "HTTP error #{response.code}" unless response.code == '201'
        value
      rescue
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        response = @backend.request_get(@path + key)
        if response.code == '200'
          value = MultiJson.load(response.body)['value']
          path = "#{@path}#{key}?rev=#{response['etag'][1..-2]}"
          response = @backend.request(::Net::HTTP::Delete.new(path))
          raise "HTTP error #{response.code}" unless response.code == '200'
          value
        end
      rescue
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#clear)
      def clear(options = {})
        @backend.request(::Net::HTTP::Delete.new(@path))
        create_db
        self
      end

      # (see Proxy#close)
      def close
        @backend.finish
        nil
      end

      private

      def create_db
        response = @backend.request_put(@path, '')
        raise "HTTP error #{response.code}" unless response.code == '201' || response.code == '412'
      end
    end
  end
end
