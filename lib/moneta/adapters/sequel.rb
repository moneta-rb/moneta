require 'sequel'

module Moneta
  module Adapters
    # Sequel backend
    # @api public
    class Sequel
      include Defaults

      # Sequel::UniqueConstraintViolation is defined since sequel 3.44.0
      # older versions raise a Sequel::DatabaseError.
      UniqueConstraintViolation = defined?(::Sequel::UniqueConstraintViolation) ? ::Sequel::UniqueConstraintViolation : ::Sequel::DatabaseError

      supports :create, :increment
      attr_reader :backend

      # @param [Hash] options
      # @option options [String] :db Sequel database
      # @option options [String/Symbol] :table (:moneta) Table name
      # @option options All other options passed to `Sequel#connect`
      # @option options [Sequel connection] :backend Use existing backend instance
      def initialize(options = {})
        table = (options.delete(:table) || :moneta).to_sym
        @backend = options[:backend] ||
          begin
            raise ArgumentError, 'Option :db is required' unless db = options.delete(:db)
            ::Sequel.connect(db, options)
          end
        @backend.create_table?(table) do
          String :k, :null => false, :primary_key => true
          Blob :v
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
        begin
          @table.insert(:k => key, :v => blob(value))
        rescue UniqueConstraintViolation
          @table.where(:k => key).update(:v => blob(value))
        end
        value
      rescue ::Sequel::DatabaseError
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#store)
      def create(key, value, options = {})
        @table.insert(:k => key, :v => blob(value))
        true
      rescue UniqueConstraintViolation
        false
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @backend.transaction do
          locked_table = @table.for_update
          if record = locked_table[:k => key]
            value = Utils.to_int(record[:v]) + amount
            locked_table.where(:k => key).update(:v => blob(value.to_s))
            value
          else
            locked_table.insert(:k => key, :v => blob(amount.to_s))
            amount
          end
        end
      rescue ::Sequel::DatabaseError
        # Concurrent modification might throw a bunch of different errors
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        if value = load(key, options)
          @table.filter(:k => key).delete
          value
        end
      end

      # (see Proxy#clear)
      def clear(options = {})
        @table.delete
        self
      end

      # (see Proxy#close)
      def close
        @backend.disconnect
        nil
      end

      private

      # See https://github.com/jeremyevans/sequel/issues/715
      def blob(s)
        s.empty? ? '' : ::Sequel.blob(s)
      end
    end
  end
end
