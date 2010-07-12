begin
  require 'bdb'
rescue LoadError
  puts "You need bdb gem to use Bdb moneta store"
  exit
end

module Moneta
  module Adapters
    class Berkeley
      include Defaults

      @@dbs = []

      def self.close_all
        @@dbs.each {|d| d.close(0) }
      end

      def initialize(options={})
        file = @file = options[:file]
        @db = Bdb::Db.new
        @db.open(nil, file, nil, Bdb::Db::BTREE, Bdb::DB_CREATE, 0)
        @@dbs << @db
      end

      def key?(key)
        nil | self[key_for(key)]
      end

      def []=(key,value)
        @db[key_for(key)] = value
      end

      def [](key)
        @db[key_for(key)]
      end

      def delete(key)
        value = self[key]
        @db.del(nil,key_for(key),0) if value
        value
      end

      def clear
        @db.truncate(nil)
      end
    end
  end
end
