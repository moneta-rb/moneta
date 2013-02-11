require 'mdb'
require 'fileutils'

module Moneta
  module Adapters
    # MDB backend
    # @api public
    class MDB
      include Defaults

      supports :create, :increment
      attr_reader :env, :db

      # @param [Hash] options
      # @option options [String or ::MDB::Environment] :env Environment directory
      # @option options [String or ::MDB::Database] :db Database name
      def initialize(options)
        @db = options.delete(:db)
        @env = options.delete(:env)

        if !(String === @db)
          raise ArgumentError, 'Option :env is not allowed' if @env
          @env = @db.environment
        elsif !(String === @env)
          raise ArgumentError, 'Option :db is required' unless @db
          @env.transaction do |txn|
            @db = @env.open(txn, @db, ::MDB::CREATE)
          end
        else
          raise ArgumentError, 'Option :env is required' unless @env
          raise ArgumentError, 'Option :db is required' unless @db
          FileUtils.mkpath(@env)
          @env = ::MDB.open(@env, options)
          @env.transaction do |txn|
            @db = @env.open(txn, @db, ::MDB::CREATE)
          end
        end
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @env.transaction(true) do |txn|
          @db.get(txn, key).nil?
        end
        true
      rescue ::MDB::Error::NOTFOUND
        false
      end

      # (see Proxy#load)
      def load(key, options = {})
        @env.transaction(true) do |txn|
          @db.get(txn, key)
        end
      rescue ::MDB::Error::NOTFOUND
        nil
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @env.transaction do |txn|
          @db.put(txn, key, value)
        end
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        @env.transaction do |txn|
          value = @db.get(txn, key)
          @db.delete(txn, key)
          value
        end
      rescue ::MDB::Error::NOTFOUND
        nil
      end

      # (see Proxy#clear)
      def clear(options = {})
        @env.transaction do |txn|
          @db.clear(txn)
        end
        self
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @env.transaction do |txn|
          value = @db.get(txn, key) rescue nil
          value = Utils.to_int(value) + amount
          @db.put(txn, key, value.to_s)
          value
        end
      end

      # (see Defaults#create)
      def create(key, value, options = {})
        @env.transaction do |txn|
          begin
            @db.get(txn, key)
            false
          rescue ::MDB::Error::NOTFOUND
            @db.put(txn, key, value)
            true
          end
        end
      end

      # (see Proxy#close)
      def close
        @db.close
        @env.close
        nil
      end
    end
  end
end
