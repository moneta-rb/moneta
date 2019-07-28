require 'faraday'
require 'multi_json'
require 'uri'

module Moneta
  module Adapters
    # CouchDB backend
    #
    # You can store hashes directly using this adapter.
    #
    # @example Store hashes
    #     db = Moneta::Adapters::Couch.new
    #     db['key'] = {a: 1, b: 2}
    #
    # @api public
    class Couch
      include Defaults

      # @api private
      class HTTPError < StandardError
        attr_reader :status, :request_method, :key

        def initialize(status, request_method, key)
          @status = status
          @request_method = request_method.to_sym
          @key = key

          super "HTTP Error: #{@status} (#{@request_method.to_s.upcase} #{@key})"
        end
      end

      attr_reader :backend

      supports :create, :each_key

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
        @backend = options[:backend] || begin
          url = "http://#{options[:host] || '127.0.0.1'}:#{options[:port] || 5984}/#{options[:db] || 'moneta'}"
          ::Faraday.new(url: url)
        end
        @rev_cache = Moneta.build do
          use :Lock
          adapter :LRUHash
        end
        create_db
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        response = @backend.head(key)
        cache_response_rev(key, response)
        response.status == 200
      end

      # (see Proxy#load)
      def load(key, options = {})
        response = @backend.get(key)
        cache_response_rev(key, response)
        response.status == 200 ? body_to_value(response.body) : nil
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        body = value_to_body(value, rev(key))
        response = @backend.put(key, body, 'Content-Type' => 'application/json')
        cache_response_rev(key, response)
        raise HTTPError.new(response.status, :put, key) unless response.status == 201
        value
      rescue HTTPError
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        delete_cached_rev(key)
        get_response = @backend.get(key)
        if get_response.status == 200
          existing_rev = get_response['etag'][1..-2]
          value = body_to_value(get_response.body)
          delete_response = @backend.delete("#{key}?rev=#{existing_rev}")
          raise HTTPError.new(response.status, :delete, key) unless delete_response.status == 200
          value
        end
      rescue HTTPError
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#clear)
      def clear(options = {})
        loop do
          response = @backend.get('_all_docs?' + encode_query(limit: 10000, sorted: false))
          raise HTTPError.new(response.status, :get, '_all_docs') unless response.status == 200
          all_docs = MultiJson.load(response.body)
          break if all_docs['rows'].empty?
          delete_docs = all_docs['rows'].map do |row|
            { _id: row['id'], _rev: row['value']['rev'], _deleted: true }
          end
          delete_response = @backend.post('_bulk_docs', MultiJson.dump(docs: delete_docs), "Content-Type" => "application/json")
          raise HTTPError.new(delete_response.status, :post, '_bulk_docs') unless delete_response.status == 201
        end

        self
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        body = value_to_body(value, nil)
        response = @backend.put(key, body, 'Content-Type' => 'application/json')
        cache_response_rev(key, response)
        case response.status
        when 201
          true
        when 409
          false
        else
          raise HTTPError.new(response.status, :put, key)
        end
      rescue HTTPError
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#each_key)
      def each_key
        return enum_for(:each_key) unless block_given?

        skip = 0
        limit = 1000
        loop do
          response = @backend.get("_all_docs?" + encode_query(limit: limit, skip: skip, sorted: false))
          case response.status
          when 200
            result = MultiJson.load(response.body)
            break if result['rows'].empty?
            skip += result['rows'].length
            result['rows'].each do |row|
              key = row['id']
              @rev_cache[key] = row['value']['rev']
              yield key
            end
          else
            raise HTTPError.new(response.status, :get, '_all_docs')
          end
        end
        self
      end

      # (see Proxy#values_at)
      def values_at(*keys, **options)
        hash = Hash[slice(*keys, **options)]
        keys.map { |key| hash[key] }
      end

      # (see Proxy#slice)
      def slice(*keys, **options)
        response = @backend.get('_all_docs?' + encode_query(keys: keys, include_docs: true))
        raise HTTPError.new(response.status, :get, '_all_docs') unless response.status == 200
        docs = MultiJson.load(response.body)
        docs["rows"].map do |row|
          next unless row['doc']
          [row['id'], doc_to_value(row['doc'])]
        end.compact
      end

      # (see Proxy#merge!)
      def merge!(pairs, options = {})
        keys = pairs.map { |key, _| key }.to_a
        cache_revs(*keys.reject { |key| @rev_cache[key] })

        if block_given?
          existing = Hash[slice(*keys, **options)]
          pairs = pairs.map do |key, new_value|
            [
              key,
              if existing.key?(key)
                yield(key, existing[key], new_value)
              else
                new_value
              end
            ]
          end
        end

        docs = pairs.map { |key, value| value_to_doc(value, @rev_cache[key], key) }.to_a
        body = MultiJson.dump(docs: docs)
        response = @backend.post('_bulk_docs', body, "Content-Type" => "application/json")
        raise HTTPError.new(response.status, :post, '_bulk_docs') unless response.status == 201
        retries = []
        MultiJson.load(response.body).each do |row|
          if row['ok'] == true
            @rev_cache[row['id']] = row['rev']
          elsif row['error'] == 'conflict'
            delete_cached_rev(row['id'])
            retries << pairs.find { |key, _| key == row['id'] }
          else
            raise "Unrecognised response: #{row}"
          end
        end

        # Recursive call with all conflicts
        if retries.empty?
          self
        else
          merge!(retries, options)
        end
      end

      private

      def body_to_value(body)
        doc_to_value(MultiJson.load(body))
      end

      def doc_to_value(doc)
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

      def value_to_doc(value, rev, id = nil)
        doc =
          case value
          when Hash
            value.merge(@type_field => 'Hash')
          when String
            { @value_field => value, @type_field => 'String' }
          when Float, Integer
            { @value_field => value, @type_field => 'Number' }
          else
            raise ArgumentError, "Invalid value type: #{value.class}"
          end
        doc['_rev'] = rev if rev
        doc['_id'] = id if id
        doc
      end

      def value_to_body(value, rev)
        MultiJson.dump(value_to_doc(value, rev))
      end

      def create_db
        loop do
          response = @backend.put('', '')
          case response.status
          when 201
            break
          when 412
            # Make sure the database really does exist
            # See https://github.com/apache/couchdb/issues/2073
            break if @backend.head('').status == 200
          else
            raise HTTPError.new(response.status, :head, '')
          end

          # Wait before trying again
          sleep 1
        end

        self
      end

      def cache_revs(*keys)
        response = @backend.get('_all_docs?' + encode_query(keys: keys))
        raise HTTPError.new(response.status, :get, '_all_docs') unless response.status == 200
        docs = MultiJson.load(response.body)
        docs['rows'].each do |row|
          next if !row['value'] || row['value']['deleted']
          @rev_cache[row['id']] = row['value']['rev']
        end
      end

      def cache_response_rev(key, response)
        case response.status
        when 200, 201
          @rev_cache[key] = response['etag'][1..-2]
        else
          delete_cached_rev(key)
          nil
        end
      end

      def delete_cached_rev(key)
        @rev_cache.delete(key)
      end

      def rev(key)
        @rev_cache[key] || begin
          response = @backend.head(key)
          cache_response_rev(key, response)
        end
      end

      def encode_query(query)
        URI.encode_www_form(query.map { |key, value| [key, MultiJson.dump(value)] })
      end
    end
  end
end
