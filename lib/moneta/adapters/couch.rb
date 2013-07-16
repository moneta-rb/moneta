require 'faraday'
require 'multi_json'

module Moneta
  module Adapters
    # CouchDB backend
    #
    # You can store hashes directly using this adapter.
    #
    # @example Store hashes
    #     db = Moneta::Adapters::Mongo.new
    #     db['key'] = {a: 1, b: 2}
    #
    # @api public
    class Couch
      include Defaults

      attr_reader :backend

      supports :create

      # @param [Hash] options
      # @option options [String] :host ('127.0.0.1') Couch host
      # @option options [String] :port (5984) Couch port
      # @option options [String] :db ('moneta') Couch database
      # @option options [String] :value_field ('value') Document field to store value
      # @option options [String] :type_field ('type') Document field to store value type
      # @option options [Faraday connection] :backend Use existing backend instance
      def initialize(options = {})
        @value_field = options[:value_field] || 'value'
        @type_field = options[:type_field] || 'type'
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
        response.status == 200 ? body_to_value(response.body) : nil
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        response = @backend.head(key)
        body = value_to_body(value, response.status == 200 && response['etag'][1..-2])
        response = @backend.put(key, body, 'Content-Type' => 'application/json')
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
          value = body_to_value(response.body)
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

      # (see Proxy#create)
      def create(key, value, options = {})
        body = value_to_body(value, nil)
        response = @backend.put(key, body, 'Content-Type' => 'application/json')
        case response.status
        when 201
          true
        when 409
          false
        else
          raise "HTTP error #{response.status}"
        end
      rescue
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      private

      def body_to_value(body)
        doc = MultiJson.load(body)
        case doc[@type_field]
        when 'Hash'
          doc = doc.dup
          doc.delete('_id')
          doc.delete('_rev')
          doc.delete(@type_field)
          doc
        else
          doc[@value_field]
        end
      end

      def value_to_body(value, rev)
        case value
        when Hash
          doc = value.merge(@type_field => 'Hash')
        when String
          doc = { @value_field => value, @type_field => 'String' }
        when Float, Fixnum
          doc = { @value_field => value, @type_field => 'Number' }
        else
          raise ArgumentError, "Invalid value type: #{value.class}"
        end
        doc['_rev'] = rev if rev
        MultiJson.dump(doc)
      end

      def create_db
        response = @backend.put '', ''
        raise "HTTP error #{response.status}" unless response.status == 201 || response.status == 412
      end
    end
  end
end
