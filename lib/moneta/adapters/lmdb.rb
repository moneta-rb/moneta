require 'lmdb'
require 'fileutils'

module Moneta
  module Adapters
    # LMDB backend
    # @api public
    class LMDB
      include Defaults

      supports :create, :increment
      attr_reader :backend, :db

      PUT_FLAGS = [:nooverwrite, :nodupdata, :current, :append, :appenddup]

      # @param [Hash] options
      # @option options [String] :dir Environment directory
      # @option options [::LMDB::Environment] :backend Use existing backend instance
      # @option options [String or nil] :db Database name
      def initialize(options)
        db = options.delete(:db)
        @backend = options.delete(:backend) ||
          begin
            raise ArgumentError, 'Option :dir is required' unless dir = options.delete(:dir)
            FileUtils.mkpath(dir)
            ::LMDB.new(dir, options)
          end

        @db = @backend.database(db, :create => true)
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        !@db.get(key).nil?
      end

      # (see Proxy#load)
      def load(key, options = {})
        @db.get(key)
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @db.put(key, value, Utils.only(options, *PUT_FLAGS))
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        @backend.transaction do
          if value = @db.get(key)
            @db.delete(key)
            value
          end
        end
      end

      # (see Proxy#clear)
      def clear(options = {})
        @db.clear
        self
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @backend.transaction do
          value = @db.get(key)
          value = Utils.to_int(value) + amount
          @db.put(key, value.to_s, Utils.only(options, *PUT_FLAGS))
          value
        end
      end

      # (see Defaults#create)
      def create(key, value, options = {})
        @backend.transaction do
          if @db.get(key)
            false
          else
            @db.put(key, value, Utils.only(options, *PUT_FLAGS))
            true
          end
        end
      end

      # (see Proxy#close)
      def close
        @backend.close
        nil
      end
    end
  end
end
