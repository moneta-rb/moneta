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

      @table_mutex = ::Mutex.new
      @table_refcount = {}

      class << self
        def release(table)
          @table_mutex.synchronize do
            if (@table_refcount[table] -= 1) <= 0
              remove_const(table.name.sub(/^.*::/, ''))
              @table_refcount.delete(table)
            end
          end
        end

        def get(options)
          name = 'Table_' << options.inspect.gsub(/[^\w]+/) do
            $&.unpack('H2' * $&.bytesize).join.upcase
          end
          @table_mutex.synchronize do
            table =
              if const_defined?(name)
                const_get(name)
              else
                create(name, options)
              end
            @table_refcount[table] ||= 0
            @table_refcount[table] += 1
            table
          end
        end

        private

        def create(name, options)
          table = Class.new(::ActiveRecord::Base)
          const_set(name, table)
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
            unless conn.table_exists?(table.table_name)
              conn.create_table(table.table_name, id: false) do |t|
                # Do not use binary key (Issue #17)
                t.string :k, null: false
                t.binary :v
              end
              conn.add_index(table.table_name, :k, unique: true)
            end
          end

          table
        rescue
          remove_const(name)
          raise
        end
      end

      # @param [Hash] options
      # @option options [String] :table ('moneta') Table name
      # @option options [Hash]   :connection ActiveRecord connection configuration
      def initialize(options = {})
        @table = self.class.get(options)
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        !@table.where(k: key).empty?
      end

      # (see Proxy#load)
      def load(key, options = {})
        record = @table.select(:v).where(k: key).first
        record && record.v
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        record = @table.select(:k).find_or_initialize_by(k: key)
        record.v = value
        record.save!
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        if record = @table.find_by(k: key)
          record.destroy
          record.v
        end
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @table.transaction do
          record = @table.lock.find_or_initialize_by(k: key)
          value = (record.v ? Utils.to_int(record.v) : 0) + amount
          record.v = value.to_s
          record.save!
          value
        end
      rescue ::ActiveRecord::RecordNotUnique, ::ActiveRecord::Deadlocked
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        @table.create(k: key, v: value)
        true
      rescue ::ActiveRecord::RecordNotUnique
        false
      end

      # (see Proxy#clear)
      def clear(options = {})
        @table.delete_all
        self
      end

      # (see Proxy#close)
      def close
        self.class.release(@table)
        @table = nil
      end
    end
  end
end
