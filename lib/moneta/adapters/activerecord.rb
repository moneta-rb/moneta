require 'active_record'

module Moneta
  module Adapters
    # ActiveRecord as key/value stores
    # @api public
    class ActiveRecord
      include Defaults

      supports :create, :increment
      attr_reader :table

      def self.tables
        @tables ||= {}
      end

      # @param [Hash] options
      # @option options [String] :table ('moneta') Table name
      # @option options [Hash]   :connection ActiveRecord connection configuration
      def initialize(options = {})
        table = options[:table] || 'moneta'
        @table = self.class.tables[table] ||=
          begin
            c = Class.new(::ActiveRecord::Base)
            c.table_name = table
            c.primary_key = :k
            c
          end

        if options[:connection]
          begin
            @table.establish_connection(options[:connection])
          rescue
            tries ||= 0
            (tries += 1) < 3 ? retry : raise
          end
        end

        unless @table.table_exists?
          @table.connection.create_table(@table.table_name, :id => false) do |t|
            # Do not use binary columns (Issue #17)
            t.string :k, :null => false
            t.string :v
          end
          @table.connection.add_index(@table.table_name, :k, :unique => true)
        end
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        !@table.where(:k => key).empty?
      end

      # (see Proxy#load)
      def load(key, options = {})
        record = @table.select(:v).where(:k => key).first
        record && record.v
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        record = @table.select(:k).where(:k => key).first_or_initialize
        record.v = value
        record.save
        value
      rescue
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        if record = @table.where(:k => key).first
          record.destroy
          record.v
        end
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
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
      rescue
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        record = @table.new
        record.k = key
        record.v = value
        record.save
        true
      rescue
        # FIXME: This catches too many errors
        # it should only catch a not-unique-exception
        false
      end

      # (see Proxy#clear)
      def clear(options = {})
        @table.delete_all
        self
      end
    end
  end
end
