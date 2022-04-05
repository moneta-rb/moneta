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
    class Couch < Adapter
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

      supports :create, :each_key

      config :value_field, default: 'value'
      config :type_field, default: 'type'
      config :login
      config :password
      config :adapter
      config :skip_create_db

      backend do |scheme: 'http', host: '127.0.0.1', port: 5984, db: 'moneta', adapter: nil, **options|
        ::Faraday.new "#{scheme}://#{host}:#{port}/#{db}", options do |faraday|
          faraday.adapter adapter if adapter
        end
      end

      # @param [Hash] options
      # @option options [String] :host ('127.0.0.1') Couch host
      # @option options [String] :port (5984) Couch port
      # @option options [String] :db ('moneta') Couch database
      # @option options [String] :scheme ('http') HTTP scheme to use
      # @option options [String] :value_field ('value') Document field to store value
      # @option options [String] :type_field ('type') Document field to store value type
      # @option options [String] :login Login name to use for HTTP basic authentication
      # @option options [String] :password Password to use for HTTP basic authentication
      # @option options [Symbol] :adapter Adapter to use with Faraday
      # @option options [Faraday::Connecton] :backend Use existing backend instance
      # @option options Other options passed to {Faraday::new} (unless
      #   :backend option is provided).
      def initialize(options = {})
        super

        if config.login && config.password
          # Faraday 1.x had a `basic_auth` function
          if backend.respond_to? :basic_auth
            backend.basic_auth(config.login, config.password)
          else
            backend.request :authorization, :basic, config.login, config.password
          end
        end

        @rev_cache = Moneta.build do
          use :Lock
          adapter :LRUHash
        end
        create_db unless config.skip_create_db
      end

      # (see Proxy#key?)
      # @option options [Boolean] :cache_rev (true) Whether to cache the rev of
      #   the document for faster updating
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
      # @option options [Boolean] :batch (false) Whether to do a
      #   {https://docs.couchdb.org/en/stable/api/database/common.html#api-doc-batch-writes
      #    batch mode write}
      # @option options [Boolean] :full_commit (nil) Set to `true` or `false`
      #   to override the server's
      #   {https://docs.couchdb.org/en/stable/config/couchdb.html#couchdb/delayed_commits
      #    commit policy}
      def store(key, value, options = {})
        put(key, value_to_doc(value, rev(key)),
            headers: full_commit_header(options[:full_commit]),
            query: options[:batch] ? { batch: 'ok' } : {},
            cache_rev: options[:cache_rev] != false,
            expect: options[:batch] ? 202 : 201)
        value
      rescue HTTPError
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#delete)
      # @option options [Boolean] :batch (false) Whether to do a
      #   {https://docs.couchdb.org/en/stable/api/database/common.html#api-doc-batch-writes
      #    batch mode write}
      # @option options [Boolean] :full_commit (nil) Set to `true` or `false`
      #   to override the server's
      #   {https://docs.couchdb.org/en/stable/config/couchdb.html#couchdb/delayed_commits
      #    commit policy}
      def delete(key, options = {})
        get_response = get(key, returns: :response)
        if get_response.success?
          value = body_to_value(get_response.body)
          existing_rev = parse_rev(get_response)
          query = { rev: existing_rev }
          query[:batch] = 'ok' if options[:batch]
          request(:delete, key,
                  headers: full_commit_header(options[:full_commit]),
                  query: query,
                  expect: options[:batch] ? 202 : 200)
          delete_cached_rev(key)
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
      # @option options [Boolean] :full_commit (nil) Set to `true` or `false`
      #   to override the server's
      #   {https://docs.couchdb.org/en/stable/config/couchdb.html#couchdb/delayed_commits
      #    commit policy}
      def clear(options = {})
        loop do
          docs = all_docs(limit: 10_000)
          break if docs['rows'].empty?
          deletions = docs['rows'].map do |row|
            { _id: row['id'], _rev: row['value']['rev'], _deleted: true }
          end
          bulk_docs(deletions, full_commit: options[:full_commit])
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
      # @option options [Boolean] :full_commit (nil) Set to `true` or `false`
      #   to override the server's
      #   {https://docs.couchdb.org/en/stable/config/couchdb.html#couchdb/delayed_commits
      #    commit policy}
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
        results = bulk_docs(docs, full_commit: options[:full_commit], returns: :doc)
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
        end

        # Recursive call with all conflicts
        if retries.empty?
          self
        else
          merge!(retries, options)
        end
      end

      private

      def full_commit_header(full_commit)
        full_commit == nil ? {} : { 'X-Couch-Full-Commit' => (!!full_commit).to_s }
      end

      def body_to_value(body)
        doc_to_value(MultiJson.load(body))
      end

      def doc_to_value(doc)
        case doc[config.type_field]
        when 'Hash'
          doc = doc.dup
          doc.delete('_id')
          doc.delete('_rev')
          doc.delete(config.type_field)
          doc
        else
          doc[config.value_field]
        end
      end

      def value_to_doc(value, rev, id = nil)
        doc =
          case value
          when Hash
            value.merge(config.type_field => 'Hash')
          when String
            { config.value_field => value, config.type_field => 'String' }
          when Float, Integer
            { config.value_field => value, config.type_field => 'Number' }
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

      def request(method, key, body = nil, returns: :nil, cache_rev: false, expect: nil, query: nil, headers: {})
        url = @backend.build_url(key, query)
        headers['Content-Type'] = 'application/json' if %i{put post}.include?(method)
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
        keys = params.delete(:keys)
        query = encode_query(params.merge(sorted: sorted))
        if keys
          post('_all_docs', { keys: keys },
               query: query,
               expect: 200,
               returns: :doc)
        else
          get('_all_docs', query: query, expect: 200)
        end
      end

      def bulk_docs(docs, returns: :success, full_commit: nil)
        post('_bulk_docs', { docs: docs },
             headers: full_commit_header(full_commit),
             returns: returns,
             expect: 201)
      end
    end
  end
end
