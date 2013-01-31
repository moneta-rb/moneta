require 'sequel'

module Moneta
  module Adapters
    # Sequel backend
    # @api public
    class Sequel
      include Defaults

      supports :create, :increment
      attr_reader :backend

      # @param [Hash] options
      # @option options [String] :db Sequel database
      # @option options [String/Symbol] :table (:moneta) Table name
      # @option options All other options passed to `Sequel#connect`
      def initialize(options = {})
        table = options.delete(:table) || :moneta
        @backend = options[:backend] ||
          begin
            raise ArgumentError, 'Option :db is required' unless db = options.delete(:db)
            ::Sequel.connect(db, options)
          end
        @backend.create_table?(table) do
          String :k, :null => false, :primary_key => true
          String :v
        end
        @table = @backend[table]
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @table[:k => key] != nil
      end

      # (see Proxy#load)
      def load(key, options = {})
        record = @table[:k => key]
        record && record[:v]
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @backend.transaction do
          begin
            @table.insert(:k => key, :v => value)
          rescue ::Sequel::DatabaseError
            @table.update(:k => key, :v => value)
          end
        end
        value
      rescue ::Sequel::DatabaseError
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#store)
      def create(key, value, options = {})
        @backend.transaction do
          @table.insert(:k => key, :v => value)
        end
        true
      rescue ::Sequel::DatabaseError
        # FIXME: This catches too many errors
        # it should only catch a not-unique-exception
        false
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @backend.transaction do
          locked_table = @table.for_update
          if record = locked_table[:k => key]
            value = Utils.to_int(record[:v]) + amount
            locked_table.update(:k => key, :v => value.to_s)
            value
          else
            locked_table.insert(:k => key, :v => amount.to_s)
            amount
          end
        end
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        @backend.transaction do
          if value = load(key, options)
            @table.filter(:k => key).delete
            value
          end
        end
      end

      # (see Proxy#clear)
      def clear(options = {})
        @table.delete
        self
      end
    end
  end
end
