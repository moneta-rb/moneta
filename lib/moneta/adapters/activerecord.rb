require 'active_record'
require 'thread'

module Moneta
  module Adapters
    # ActiveRecord as key/value stores
    # @api public
    class ActiveRecord
      include Defaults

      supports :create, :increment
      attr_reader :table

      @tables = {}
      @tables_reverse = {}
      @tables_count = {}
      @tables_mutex = ::Mutex.new

      def self.create_table(options)
        @tables_mutex.synchronize do
          unless table = @tables[options]
            table = Class.new(::ActiveRecord::Base)
            table.table_name = options[:table] || 'moneta'
            table.primary_key = :k

            if options[:connection]
              begin
                table.establish_connection(options[:connection])
              rescue
                tries ||= 0
                (tries += 1) < 3 ? retry : raise
              end
            end

            table.connection_pool.with_connection do |conn|
              unless table.table_exists?
                conn.create_table(table.table_name, :id => false) do |t|
                  # Do not use binary key (Issue #17)
                  t.string :k, :null => false
                  t.binary :v
                end
                conn.add_index(table.table_name, :k, :unique => true)
              end
            end

            @tables[options] = table
            @tables_reverse[table] = options
          end
          @tables_count[options] ||= 0
          @tables_count[options] += 1
          table
        end
      end

      def self.delete_table(table)
        @tables_mutex.synchronize do
          options = @tables_reverse[table]
          if (@tables_count[options] -= 1) == 0
            @tables_reverse.delete(table)
            @tables_count.delete(options)
            @tables.delete(options)
          end
        end
      end

      # @param [Hash] options
      # @option options [String] :table ('moneta') Table name
      # @option options [Hash]   :connection ActiveRecord connection configuration
      def initialize(options = {})
        @table = self.class.create_table(options)
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @table.connection_pool.with_connection do
          !@table.where(:k => key).empty?
        end
      end

      # (see Proxy#load)
      def load(key, options = {})
        @table.connection_pool.with_connection do
          record = @table.select(:v).where(:k => key).first
          record && record.v
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @table.connection_pool.with_connection do
          record = @table.select(:k).where(:k => key).first_or_initialize
          record.v = value
          record.save
          value
        end
      rescue
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        @table.connection_pool.with_connection do
          if record = @table.where(:k => key).first
            record.destroy
            record.v
          end
        end
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @table.connection_pool.with_connection do
          @table.transaction do
            if record = @table.where(:k => key).lock.first
              value = Utils.to_int(record.v) + amount
              record.v = value.to_s
              record.save
              value
            elsif create(key, amount.to_s, options)
              amount
            else
              raise 'Concurrent modification'
            end
          end
        end
      rescue
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        @table.connection_pool.with_connection do
          record = @table.new
          record.k = key
          record.v = value
          record.save
          true
        end
      rescue
        # FIXME: This catches too many errors
        # it should only catch a not-unique-exception
        false
      end

      # (see Proxy#clear)
      def clear(options = {})
        @table.connection_pool.with_connection do
          @table.delete_all
        end
        self
      end

      # (see Proxy#close)
      def close
        self.class.delete_table(@table)
        @table = nil
      end
    end
  end
end
