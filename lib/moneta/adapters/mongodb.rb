begin
  require "mongo"
rescue LoadError
  puts "You need the mongo gem to use the MongoDB moneta store"
  exit
end

module Moneta
  module Adapters
    class MongoDB
      include Moneta::Defaults

      def initialize(options = {})
        options = {
          :host => ENV['MONGO_RUBY_DRIVER_HOST'] || 'localhost',
          :port => ENV['MONGO_RUBY_DRIVER_PORT'] || Mongo::Connection::DEFAULT_PORT,
          :db => 'cache',
          :collection => 'cache'
        }.update(options)
        conn = Mongo::Connection.new(options[:host], options[:port])
        @cache = conn.db(options[:db]).collection(options[:collection])
      end

      def key?(key, *)
        !!self[key]
      end

      def [](key)
        res = @cache.find_one('_id' => key_for(key))
        res && deserialize(res['data'].to_s)
      end

      def delete(key, *)
        string_key = key_for(key)

        value = self[key]
        @cache.remove('_id' => string_key) if value
        value
      end

      def store(key, value, *)
        key = key_for(key)
        serialized_value = BSON::ByteBuffer.new serialize(value)
        @cache.insert({ '_id' => key, 'data' => serialized_value })
      end

      def clear(*)
        @cache.remove
      end
    end
  end
end

