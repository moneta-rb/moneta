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
        url = "http://#{options[:host] || '127.0.0.1'}:#{options[:port] || 5984}/#{options[:db] || 'moneta'}"
        @backend = options[:backend] || ::Faraday.new(url: url)
        @rev_cache = Moneta.build do
          use :Lock
          adapter :LRUHash
        end
        create_db
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        response = @backend.head(key)
        update_rev_cache(key, response)
        response.status == 200
      end

      # (see Proxy#load)
      def load(key, options = {})
        response = @backend.get(key)
        update_rev_cache(key, response)
        response.status == 200 ? body_to_value(response.body) : nil
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        body = value_to_body(value, rev(key))
        response = @backend.put(key, body, 'Content-Type' => 'application/json')
        update_rev_cache(key, response)
        raise "HTTP error #{response.status} (PUT /#{key})" unless response.status == 201
        value
      rescue
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        clear_rev_cache(key)
        get_response = @backend.get(key)
        if get_response.status == 200
          existing_rev = get_response['etag'][1..-2]
          value = body_to_value(get_response.body)
          delete_response = @backend.delete("#{key}?rev=#{existing_rev}")
          raise "HTTP error #{response.status}" unless delete_response.status == 200
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
        update_rev_cache(key, response)
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

      # (see Proxy#each_key)
      def each_key
        return enum_for(:each_key) unless block_given?

        skip = 0
        limit = 1000
        total_rows = 1
        while total_rows > skip do
          response = @backend.get("_all_docs?" + encode_query(limit: limit, skip: skip))
          case response.status
          when 200
            result = MultiJson.load(response.body)
            total_rows = result['total_rows']
            skip += result['rows'].length
            result['rows'].each do |row|
              key = row['id']
              @rev_cache[key] = row['value']['rev']
              yield key
            end
          else
            raise "HTTP error #{response.status}"
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
        raise "HTTP error #{response.status}" unless response.status == 200
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
        raise "HTTP error #{response.status}" unless response.status == 201
        retries = []
        MultiJson.load(response.body).each do |row|
          if row['ok'] == true
            @rev_cache[row['id']] = row['rev']
          elsif row['error'] == 'conflict'
            clear_rev_cache(row['id'])
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
        100.times do
          response = @backend.put('', '')
          case response.status
          when 201
            break
          when 412
            # Make sure the database really does exist
            break if @backend.head('').status == 200
          else
            raise "HTTP error #{response.status}"
          end

          # Wait before trying again
          sleep 1
        end
      end

      def cache_revs(*keys)
        response = @backend.get('_all_docs?' + encode_query(keys: keys))
        raise "HTTP error #{response.status}" unless response.status == 200
        docs = MultiJson.load(response.body)
        docs['rows'].each do |row|
          next unless row['value']
          @rev_cache[row['id']] = row['value']['rev']
        end
      end

      def update_rev_cache(key, response)
        case response.status
        when 200, 201
          @rev_cache[key] = response['etag'][1..-2]
        else
          clear_rev_cache(key)
          nil
        end
      end

      def clear_rev_cache(key)
        @rev_cache.delete(key)
      end

      def rev(key)
        @rev_cache[key] || (
          response = @backend.head(key) and
          update_rev_cache(key, response)).tap do |rev|
        end
      end

      def encode_query(query)
        URI.encode_www_form(query.map { |key, value| [key, MultiJson.dump(value)] })
      end
    end
  end
end
