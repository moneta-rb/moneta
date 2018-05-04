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
      # @option options [String, Symbol] :table (:moneta) Table name
      # @option options [Array] :extensions ([]) List of Sequel extensions
      # @option options [Integer] :connection_validation_timeout (nil) Sequel connection_validation_timeout
      # @option options [Sequel::Database] :backend Use existing backend instance
      # @option options [Boolean] :no_opt Do not apply database-specific optimisations
      # @option options All other options passed to `Sequel#connect`
      def self.new(*args)
        # Calls to subclass.new (below) are differentiated by # of args
        return super if args.length == 2
        options = args.first || {}

        extensions = options.delete(:extensions)
        connection_validation_timeout = options.delete(:connection_validation_timeout)
        no_opt = options.delete(:no_opt)
        backend = options.delete(:backend) ||
          begin
            raise ArgumentError, 'Option :db is required' unless db = options.delete(:db)
            ::Sequel.connect(db, options.reject { |k,_| k == :table }).tap do |backend|
              if extensions
                raise ArgumentError, 'Option :extensions must be an Array' unless extensions.is_a?(Array)
                extensions.map(&:to_sym).each(&backend.method(:extension))
              end

              if connection_validation_timeout
                backend.pool.connection_validation_timeout = connection_validation_timeout
              end
            end
          end

        if no_opt
          super(options, backend)
        else
          case backend.database_type
          when :mysql
            MySQL.new(options, backend)
          when :postgres
            Postgres.new(options, backend)
          when :sqlite
            SQLite.new(options, backend)
          else
            super(options, backend)
          end
        end
      end

      # @api private
      def initialize(options, backend)
        @backend = backend
        @table_name = (options.delete(:table) || :moneta).to_sym

        @backend.create_table?(@table_name) do
          String :k, null: false, primary_key: true
          File :v
        end
        @table = @backend[@table_name]
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        !@table.where(k: key).empty?
      end

      # (see Proxy#load)
      def load(key, options = {})
        @table.where(k: key).get(:v)
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        blob_value = blob(value)
        unless @table.where(k: key).update(v: blob(value)) == 1
          @table.insert(k: key, v: blob(value))
        end
        value
      rescue ::Sequel::DatabaseError
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#store)
      def create(key, value, options = {})
        @table.insert(k: key, v: blob(value))
        true
      rescue UniqueConstraintViolation
        false
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @backend.transaction do
          if existing = @table.where(k: key).for_update.get(:v)
            total = amount + Integer(existing)
            raise "no update" unless @table.where(k: key).update(v: blob(total.to_s)) == 1
            total
          else
            @table.insert(k: key, v: blob(amount.to_s))
            amount
          end
        end
      rescue
        # Concurrent modification might throw a bunch of different errors
        tries ||= 0
        (tries += 1) < 10 ? retry : raise
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = load(key, options)
        @table.filter(k: key).delete
        value
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

      # @api private
      class MySQL < Sequel
        def store(key, value, options = {})
          @table.on_duplicate_key_update(v: ::Sequel[:values].function(:v)).insert(k: key, v: blob(value))
          value
        end

        def increment(key, amount = 1, options = {})
          @backend.transaction do
            if existing = load(key)
              Integer(existing)
            end
            @table.on_duplicate_key_update(v: ::Sequel.+(:v, ::Sequel[:values].function(:v))).insert(k: key, v: amount)
            load(key).to_i
          end
        rescue ::Sequel::SerializationFailure # Thrown on deadlock
          tries ||= 0
          (tries += 1) <= 3 ? retry : raise
        end
      end

      # @api private
      class Postgres < Sequel
        def store(key, value, options = {})
          @table.insert_conflict(target: :k, update: {v: ::Sequel[:excluded][:v]}).insert(k: key, v: blob(value))
          value
        end

        def increment(key, amount = 1, options = {})
          update_expr = ::Sequel[:convert_to].function(
            ::Sequel.cast(
              ::Sequel.cast(
                ::Sequel[:convert_from].function(::Sequel[@table_name][:v], 'UTF8'),
                Integer) + amount,
              String),
            'UTF8')

          if row = @table.
            returning(:v).
            insert_conflict(target: :k, update: {v: update_expr}).
            insert(k: key, v: blob(amount.to_s)).
            first
          then
            row[:v].to_i
          end
        end

        def delete(key, options = {})
          if row = @table.returning(:v).where(k: key).delete.first
            row[:v]
          end
        end
      end

      # @api private
      class SQLite < Sequel
        def store(key, value, options = {})
          @table.insert_conflict(:replace).insert(k: key, v: blob(value))
          value
        end
      end
    end
  end
end
