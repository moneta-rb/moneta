require 'mongo'

module Moneta
  module Adapters
    # MongoDB backend
    #
    # Supports expiration, documents will be automatically removed starting
    # with mongodb >= 2.2 (see {http://docs.mongodb.org/manual/tutorial/expire-data/}).
    #
    # You can store hashes directly using this adapter.
    #
    # @example Store hashes
    #     db = Moneta::Adapters::MongoOfficial.new
    #     db['key'] = {a: 1, b: 2}
    #
    # @api public
    class Mongo < Adapter
      include ExpiresSupport

      supports :each_key, :create, :increment

      config :collection, default: 'moneta'

      config :db
      config :database, default: 'moneta' do |database:, db:, **|
        if db
          warn('Moneta::Adapters::Mongo - the :db option is deprecated and will be removed in a future version. Use :database instead')
          db
        else
          database
        end
      end

      config :expires_field, default: 'expiresAt'
      config :value_field, default: 'value'
      config :type_field, default: 'type'

      backend do |host: '127.0.0.1', port: 27017, **options|
        options[:logger] ||= ::Logger.new(STDERR).tap do |logger|
          logger.level = ::Logger::ERROR
        end
        ::Mongo::Client.new(["#{host}:#{port}"], options)
      end

      # @param [Hash] options
      # @option options [String] :collection ('moneta') MongoDB collection name
      # @option options [String] :host ('127.0.0.1') MongoDB server host
      # @option options [String] :user Username used to authenticate
      # @option options [String] :password Password used to authenticate
      # @option options [Integer] :port (MongoDB default port) MongoDB server port
      # @option options [String] :database ('moneta') MongoDB database
      # @option options [Integer] :expires Default expiration time
      # @option options [String] :expires_field ('expiresAt') Document field to store expiration time
      # @option options [String] :value_field ('value') Document field to store value
      # @option options [String] :type_field ('type') Document field to store value type
      # @option options [::Mongo::Client] :backend Use existing backend instance
      # @option options Other options passed to `Mongo::MongoClient#new`
      def initialize(options = {})
        super

        @database = backend.use(config.database)
        @collection = @database[config.collection]

        if @database.command(buildinfo: 1).documents.first['version'] >= '2.2'
          @collection.indexes.create_one({ config.expires_field => 1 }, expire_after: 0)
        else
          warn 'Moneta::Adapters::Mongo - You are using MongoDB version < 2.2, expired documents will not be deleted'
        end
      end

      # (see Proxy#load)
      def load(key, options = {})
        view = @collection.find(:$and => [
                                  { _id: to_binary(key) },
                                  not_expired
                                ])

        doc = view.limit(1).first

        if doc
          update_expiry(options, nil) do |expires|
            view.update_one(:$set => { config.expires_field => expires })
          end

          doc_to_value(doc)
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        key = to_binary(key)
        @collection.replace_one({ _id: key },
                                value_to_doc(key, value, options),
                                upsert: true)
        value
      end

      # (see Proxy#each_key)
      def each_key
        return enum_for(:each_key) unless block_given?
        @collection.find.each { |doc| yield from_binary(doc[:_id]) }
        self
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        key = to_binary(key)
        if doc = @collection.find(_id: key).find_one_and_delete and
            !doc[config.expires_field] || doc[config.expires_field] >= Time.now
          doc_to_value(doc)
        end
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @collection.find_one_and_update({ :$and => [{ _id: to_binary(key) }, not_expired] },
                                        { :$inc => { config.value_field => amount } },
                                        return_document: :after,
                                        upsert: true)[config.value_field]
      rescue ::Mongo::Error::OperationFailure
        tries ||= 0
        (tries += 1) < 3 ? retry : raise
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        key = to_binary(key)
        @collection.insert_one(value_to_doc(key, value, options))
        true
      rescue ::Mongo::Error::OperationFailure => ex
        raise unless ex.message =~ /^E11000 / # duplicate key error
        false
      end

      # (see Proxy#clear)
      def clear(options = {})
        @collection.delete_many
        self
      end

      # (see Proxy#close)
      def close
        @database.close
        nil
      end

      # (see Proxy#slice)
      def slice(*keys, **options)
        view = @collection.find(:$and => [
                                  { _id: { :$in => keys.map(&method(:to_binary)) } },
                                  not_expired
                                ])
        pairs = view.map { |doc| [from_binary(doc[:_id]), doc_to_value(doc)] }

        update_expiry(options, nil) do |expires|
          view.update_many(:$set => { config.expires_field => expires })
        end

        pairs
      end

      # (see Proxy#merge!)
      def merge!(pairs, options = {})
        existing = Hash[slice(*pairs.map { |key, _| key })]
        update_pairs, insert_pairs = pairs.partition { |key, _| existing.key?(key) }

        @collection.insert_many(insert_pairs.map do |key, value|
          value_to_doc(to_binary(key), value, options)
        end)

        update_pairs.each do |key, value|
          value = yield(key, existing[key], value) if block_given?
          binary = to_binary(key)
          @collection.replace_one({ _id: binary }, value_to_doc(binary, value, options))
        end

        self
      end

      # (see Proxy#fetch_values)
      def fetch_values(*keys, **options)
        return values_at(*keys, **options) unless block_given?
        hash = Hash[slice(*keys, **options)]
        keys.map do |key|
          if hash.key?(key)
            hash[key]
          else
            yield key
          end
        end
      end

      # (see Proxy#values_at)
      def values_at(*keys, **options)
        hash = Hash[slice(*keys, **options)]
        keys.map { |key| hash[key] }
      end

      private

      def doc_to_value(doc)
        case doc[config.type_field]
        when 'Hash'
          doc = doc.dup
          doc.delete('_id')
          doc.delete(config.type_field)
          doc.delete(config.expires_field)
          doc
        when 'Number'
          doc[config.value_field]
        else
          # In ruby_bson version 2 (and probably up), #to_s no longer returns the binary data
          from_binary(doc[config.value_field])
        end
      end

      def value_to_doc(key, value, options)
        case value
        when Hash
          value.merge('_id' => key,
                      config.type_field => 'Hash',
                      # expires_field must be a Time object (BSON date datatype)
                      config.expires_field => expires_at(options) || nil)
        when Float, Integer
          { '_id' => key,
            config.type_field => 'Number',
            config.value_field => value,
            # expires_field must be a Time object (BSON date datatype)
            config.expires_field => expires_at(options) || nil }
        when String
          intvalue = value.to_i
          { '_id' => key,
            config.type_field => 'String',
            config.value_field => intvalue.to_s == value ? intvalue : to_binary(value),
            # @expires_field must be a Time object (BSON date datatype)
            config.expires_field => expires_at(options) || nil }
        else
          raise ArgumentError, "Invalid value type: #{value.class}"
        end
      end

      # BSON will use String#force_encoding to make the string 8-bit
      # ASCII.  This could break unicode text so we should dup in this
      # case, and it also fails with frozen strings.
      def to_binary(str)
        str = str.dup if str.frozen? || str.encoding != Encoding::ASCII_8BIT
        ::BSON::Binary.new(str)
      end

      def from_binary(binary)
        binary.is_a?(::BSON::Binary) ? binary.data : binary.to_s
      end

      def not_expired
        {
          :$or => [
            { config.expires_field => nil },
            { config.expires_field => { :$gte => Time.now } }
          ]
        }
      end

      def update_expiry(options, default)
        if (expires = expires_at(options, default)) != nil
          yield(expires || nil)
        end
      end
    end
  end
end
