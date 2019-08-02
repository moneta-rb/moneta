require 'faraday'
require 'multi_json'

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
      # @option options [String] :scheme ('http') HTTP scheme to use
      # @option options [String] :value_field ('value') Document field to store value
      # @option options [String] :type_field ('type') Document field to store value type
      # @option options [Symbol] :adapter Adapter to use with Faraday
      # @option options [Faraday::Connecton] :backend Use existing backend instance
      # @option options Other options passed to {Faraday::new} (unless
      #   :backend option is provided).
      def initialize(options = {})
        @value_field = options.delete(:value_field) || 'value'
        @type_field = options.delete(:type_field) || 'type'
        @backend = options.delete(:backend) || begin
          host = options.delete(:host) || '127.0.0.1'
          port = options.delete(:port) || 5984
          db = options.delete(:db) || 'moneta'
          scheme = options.delete(:scheme) || 'http'
          block = if faraday_adapter = options.delete(:adapter)
                    proc { |faraday| faraday.adapter(faraday_adapter) }
                  end
          ::Faraday.new("#{scheme}://#{host}:#{port}/#{db}", options, &block)
        end
        @rev_cache = Moneta.build do
          use :Lock
          adapter :LRUHash
        end
        create_db
      end

      # (see Proxy#key?)
      # @option options [Boolean] :cache_rev (true) Whether to cache the rev of the document for faster updating
      def key?(key, options = {})
        cache_rev = options[:cache_rev] != false
        head(key, cache_rev: cache_rev)
      end

      # (see Proxy#load)
      # @option (see #key?)
      def load(key, options = {})
        cache_rev = options[:cache_rev] != false
        doc = get(key, cache_rev: cache_rev)
        doc ? doc_to_value(doc) : nil
      end

      # (see Proxy#store)
      # @option (see #key?)
      def store(key, value, options = {})
        cache_rev = options[:cache_rev] != false
        put(key, value_to_doc(value, rev(key)), cache_rev: cache_rev, expect: 201)
        value
      rescue HTTPError
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        get_response = get(key, returns: :response)
        if get_response.success?
          value = body_to_value(get_response.body)
          existing_rev = parse_rev(get_response)
          request(:delete, key, query: { rev: existing_rev }, expect: 200)
          value
        end
      rescue HTTPError
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#clear)
      # @option options [Boolean] :compact (false) Whether to compact the database after clearing
      # @option options [Boolean] :await_compact (false) Whether to wait for compaction to complete
      #   before returning.
      def clear(options = {})
        loop do
          docs = all_docs(limit: 10_000)
          break if docs['rows'].empty?
          deletions = docs['rows'].map do |row|
            { _id: row['id'], _rev: row['value']['rev'], _deleted: true }
          end
          bulk_docs(deletions)
        end

        # Compact the database unless told not to
        if options[:compact]
          post('_compact', expect: 202)

          # Performance won't be great while compaction is happening, so by default we wait for it
          if options[:await_compact]
            loop do
              db_info = get('', expect: 200)
              break unless db_info['compact_running']

              # wait before checking again
              sleep 1
            end
          end
        end

        self
      end

      # (see Proxy#create)
      # @option (see #key?)
      def create(key, value, options = {})
        cache_rev = options[:cache_rev] != false
        doc = value_to_doc(value, nil)
        response = put(key, doc, cache_rev: cache_rev, returns: :response)
        case response.status
        when 201
          true
        when 409
          false
        else
          raise HTTPError.new(response.status, :put, @backend.create_url(key))
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
          docs = all_docs(limit: limit, skip: skip)
          break if docs['rows'].empty?
          skip += docs['rows'].length
          docs['rows'].each do |row|
            key = row['id']
            @rev_cache[key] = row['value']['rev']
            yield key
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
        docs = all_docs(keys: keys, include_docs: true)
        docs["rows"].map do |row|
          next unless doc = row['doc']
          [row['id'], doc_to_value(doc)]
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
        results = bulk_docs(docs, returns: :doc)
        retries = results.each_with_object([]) do |row, retries|
          ok, id = row.values_at('ok', 'id')
          if ok
            @rev_cache[id] = row['rev']
          elsif row['error'] == 'conflict'
            delete_cached_rev(id)
            retries << pairs.find { |key,| key == id }
          else
            raise "Unrecognised response: #{row}"
          end
          retries
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

      def create_db
        loop do
          response = put('', returns: :response)
          case response.status
          when 201
            break
          when 412
            # Make sure the database really does exist
            # See https://github.com/apache/couchdb/issues/2073
            break if head('')
          else
            raise HTTPError.new(response.status, :put, '')
          end

          # Wait before trying again
          sleep 1
        end

        self
      end

      def cache_revs(*keys)
        docs = all_docs(keys: keys)
        docs['rows'].each do |row|
          next if !row['value'] || row['value']['deleted']
          @rev_cache[row['id']] = row['value']['rev']
        end
      end

      def parse_rev(response)
        response['etag'][1..-2]
      end

      def cache_response_rev(key, response)
        case response.status
        when 200, 201
          @rev_cache[key] = parse_rev(response)
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
        query.map { |key, value| [key, MultiJson.dump(value)] }
      end

      def request(method, key, body = nil, returns: :nil, cache_rev: false, expect: nil, query: nil)
        url = @backend.build_url(key, query)
        headers = %i{put post}.include?(method) ? { 'Content-Type' => 'application/json' } : {}
        response = @backend.run_request(method, url, body || '', headers)

        if cache_rev
          cache_response_rev(key, response)
        end

        if expect
          raise HTTPError.new(response.status, method, url) unless response.status == expect
        end

        case returns
        when :response
          response
        when :success
          response.success?
        when :doc
          response.success? ? MultiJson.load(response.body) : nil
        when :nil
          nil
        else
          raise "Unknown returns param: #{returns.inspect}"
        end
      end

      def get(key, returns: :doc, **options)
        request(:get, key, returns: returns, **options)
      end

      def head(key, returns: :success, **options)
        request(:head, key, returns: returns, **options)
      end

      def put(key, doc = nil, returns: :success, **options)
        body = doc == nil ? '' : MultiJson.dump(doc)
        request(:put, key, body, returns: returns, **options)
      end

      def post(key, doc = nil, returns: :success, **options)
        body = doc == nil ? '' : MultiJson.dump(doc)
        request(:post, key, body, returns: returns, **options)
      end

      def all_docs(sorted: false, **params)
        get('_all_docs', query: encode_query(params.merge(sorted: sorted)), expect: 200)
      end

      def bulk_docs(docs, returns: :success)
        post('_bulk_docs', { docs: docs }, returns: returns, expect: 201)
      end
    end
  end
end
