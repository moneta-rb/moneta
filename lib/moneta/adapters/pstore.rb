require 'pstore'
require 'fileutils'

module Moneta
  module Adapters
    # PStore backend
    # @api public
    class PStore
      include Defaults

      # The each_key support is not advertised until we allow "checking and retrieving entries while enumerating"
      supports :create, :increment #, :each_key
      attr_reader :backend

      # @param [Hash] options
      # @option options [String] :file PStore file
      # @option options [::PStore] :backend Use existing backend instance
      def initialize(options = {})
        @backend = options[:backend] ||
          begin
            raise ArgumentError, 'Option :file is required' unless options[:file]
            FileUtils.mkpath(::File.dirname(options[:file]))
            new_store(options)
          end

        @id = "Moneta::Adapters::PStore(#{object_id})"
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        transaction(true) { @backend.root?(key) }
      end

      # (see Proxy#each_key)
      def each_key(&block)
        return enum_for(:each_key) { @backend.transaction(true) { @backend.roots.size } } unless block_given?

        @backend.transaction(true) do
          @backend.roots.each { |k| yield(k) }
        end
        self
      end

      # (see Proxy#load)
      def load(key, options = {})
        transaction(true) { @backend[key] }
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        transaction {@backend[key] = value }
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        transaction { @backend.delete(key) }
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        transaction do
          value = Utils.to_int(@backend[key]) + amount
          @backend[key] = value.to_s
          value
        end
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        transaction do
          if @backend.root?(key)
            false
          else
            @backend[key] = value
            true
          end
        end
      end

      # (see Proxy#clear)
      def clear(options = {})
        transaction do
          @backend.roots.each do |key|
            @backend.delete(key)
          end
        end
        self
      end

      protected

      class TransactionError < StandardError; end

      def new_store(options)
        ::PStore.new(options[:file], options[:threadsafe])
      end

      def transaction(read_only = false)
        case Thread.current[@id]
        when read_only, true
          yield
        when false
          raise TransactionError, "Attempt to start read-write transaction inside a read-only transaction"
        else
          begin
            Thread.current[@id] = read_only
            @backend.transaction(read_only) { yield }
          ensure
            Thread.current[@id] = nil
          end
        end
      end
    end
  end
end
