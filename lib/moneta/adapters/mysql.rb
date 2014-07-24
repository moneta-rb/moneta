require 'mysql2'

module Moneta
  module Adapters
    # MySQL backend
    # @api public
    class Mysql
      include Defaults
      include IncrementSupport

      supports :create
      attr_reader :backend

      # @param [Hash] options
      # @option options [String] :table ('moneta') Table name
      # @option options [::Mysql2::Client] :backend Use existing backend instance
      # @option options Other options passed to `Mysql2::Client#new`
      def initialize(options = {})
        @table = options.delete(:table) || 'moneta'
        @backend = options[:backend] ||
          begin
            ::Mysql2::Client.new(options)
          end
        @backend.query("create table if not exists #{@table} (k blob not null primary key, v blob)")
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        !@backend.query("select v from #{@table} where k = '#{@backend.escape key}'", :cast => false).empty?
      end

      # (see Proxy#load)
      def load(key, options = {})
        rows = @backend.query("select v from #{@table} where k = '#{@backend.escape key}'", :cast => false)
        rows.empty? ? nil : rows.first.first
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @backend.query("replace into #{@table} values (#{@backend.escape key}, #{@backend.escape value})"),
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = load(key, options)
        @backend.query("delete from #{@table} where k = '#{@backend.escape key}'")
        value
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        # @backend.transaction(:exclusive) { return super }
      end

      # (see Proxy#clear)
      def clear(options = {})
        @backend.query("truncate #{@table}")
        self
      end

      # (see Default#create)
      def create(key, value, options = {})
        false
      end

      # (see Proxy#close)
      def close
        @backend.close
        nil
      end
    end
  end
end
