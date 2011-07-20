# encoding: utf-8

begin
  require "mongo"
rescue LoadError
  puts "You need the mongo gem to use the MongoDB moneta store"
  exit
end
require 'uri'

module Moneta
  module Adapters
    class MongoDB
      include Moneta::Defaults

      def initialize(options = {})
        collection = options.delete(:collection) || 'cache'

        if uri = options.delete(:uri)
          db_name = URI.parse(uri).path.sub('/','')
          db_name ||= options.delete :db
          conn = Mongo::Connection.from_uri uri, options
        else
          options = {
            :host => ENV['MONGO_RUBY_DRIVER_HOST'] || 'localhost',
            :port => ENV['MONGO_RUBY_DRIVER_PORT'] || Mongo::Connection::DEFAULT_PORT,
            :db => 'cache'
          }.update(options)

          host = options.delete :host
          port = options.delete :port
          db_name = options.delete :db

          conn = Mongo::Connection.new(host, port, options)
        end
        db = conn.db db_name
        @cache = db.collection collection
      end

      def key?(key, *)
        !!self[key]
      end

      def [](key)
        res = @cache.find_one('_id' => key_for(key))
        res ? res['data'] : nil
      end

      def delete(key, *)
        string_key = key_for(key)

        value = self[key]
        @cache.remove('_id' => string_key) if value
        value
      end

      def store(key, value, *)
        key = key_for(key)
        @cache.update({ '_id' => key },
                      { '_id' => key, 'data' => value },
                      { :upsert => true })
      end

      def clear(*)
        @cache.remove
      end
    end
  end
end

