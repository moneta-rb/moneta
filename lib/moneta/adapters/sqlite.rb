require 'sqlite3'

module Moneta
  module Adapters
    # Sqlite3 backend
    # @api public
    class Sqlite
      include Defaults
      include IncrementSupport

      supports :create, :each_key
      attr_reader :backend

      # @param [Hash] options
      # @option options [String] :file Database file
      # @option options [String] :table ('moneta') Table name
      # @option options [Integer] :busy_timeout (1000) Sqlite timeout if database is busy
      # @option options [::Sqlite3::Database] :backend Use existing backend instance
      # @option options [String, Symbol] :journal_mode Set the journal mode for the connection
      def initialize(options = {})
        @table = options[:table] || 'moneta'
        @backend = options[:backend] ||
          begin
            raise ArgumentError, 'Option :file is required' unless options[:file]
            ::SQLite3::Database.new(options[:file])
          end
        @backend.busy_timeout(options[:busy_timeout] || 1000)
        @backend.execute("create table if not exists #{@table} (k blob not null primary key, v blob)")
        if journal_mode = options[:journal_mode]
          @backend.journal_mode = journal_mode.to_s
        end
        @stmts =
          [@exists = @backend.prepare("select exists(select 1 from #{@table} where k = ?)"),
           @select = @backend.prepare("select v from #{@table} where k = ?"),
           @replace = @backend.prepare("replace into #{@table} values (?, ?)"),
           @delete = @backend.prepare("delete from #{@table} where k = ?"),
           @clear = @backend.prepare("delete from #{@table}"),
           @create = @backend.prepare("insert into #{@table} values (?, ?)"),
           @keys = @backend.prepare("select k from #{@table}"),
           @count = @backend.prepare("select count(*) from #{@table}")]

        version = @backend.execute("select sqlite_version()").first.first
        if @can_upsert = ::Gem::Version.new(version) >= ::Gem::Version.new('3.24.0')
          @stmts << (@increment = @backend.prepare <<-SQL)
            insert into #{@table} values (?, ?)
            on conflict (k)
            do update set v = cast(cast(v as integer) + ? as blob)
            where v = '0' or v = X'30' or cast(v as integer) != 0
          SQL
        end
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @exists.execute!(key).first.first.to_i == 1
      end

      # (see Proxy#load)
      def load(key, options = {})
        rows = @select.execute!(key)
        rows.empty? ? nil : rows.first.first
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @replace.execute!(key, value)
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = load(key, options)
        @delete.execute!(key)
        value
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @backend.transaction(:exclusive) { return super } unless @can_upsert
        @backend.transaction do
          @increment.execute!(key, amount.to_s, amount)
          return Integer(load(key))
        end
      end

      # (see Proxy#clear)
      def clear(options = {})
        @clear.execute!
        self
      end

      # (see Default#create)
      def create(key, value, options = {})
        @create.execute!(key, value)
        true
      rescue SQLite3::ConstraintException
        # If you know a better way to detect whether an insert-ignore
        # suceeded, please tell me.
        @create.reset!
        false
      end

      # (see Proxy#close)
      def close
        @stmts.each { |s| s.close }
        @backend.close
        nil
      end

      # (see Proxy#slice)
      def slice(*keys, **options)
        query = "select k, v from #{@table} where k in (#{(['?'] * keys.length).join(',')})"
        @backend.execute(query, keys)
      end

      # (see Proxy#values_at)
      def values_at(*keys, **options)
        hash = Hash[slice(*keys, **options)]
        keys.map { |key| hash[key] }
      end

      # (see Proxy#fetch_values)
      def fetch_values(*keys, **options)
        return values_at(*keys, **options) unless block_given?
        hash = Hash[slice(*keys, **options)]
        keys.map do |key|
          if hash.key?(key)
            hash[key]
          else
            yield key
          end
        end
      end

      # (see Proxy#merge!)
      def merge!(pairs, options = {})
        transaction = @backend.transaction if block_given?

        if block_given?
          existing = Hash[slice(*pairs.map { |k, _| k }.to_a)]
          pairs = pairs.map do |key, new_value|
            new_value = yield(key, existing[key], new_value) if existing.key?(key)
            [key, new_value]
          end.to_a
        else
          pairs = pairs.to_a
        end

        query = "replace into #{@table} (k, v) values" + (['(?, ?)'] * pairs.length).join(',')
        @backend.query(query, pairs.flatten).close
      rescue
        @backend.rollback if transaction
        raise
      else
        @backend.commit if transaction
        self
      end

      # (see Proxy#each_key)
      def each_key
        return enum_for(:each_key) { @count.execute!.first.first } unless block_given?
        @keys.execute!.each do |row|
          yield row.first
        end
        self
      end
    end
  end
end
