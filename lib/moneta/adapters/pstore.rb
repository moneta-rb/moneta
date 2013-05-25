require 'pstore'
require 'fileutils'

module Moneta
  module Adapters
    # PStore backend
    # @api public
    class PStore
      include Defaults

      supports :create, :increment
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
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @backend.transaction(true) { @backend.root?(key) }
      end

      # (see Proxy#load)
      def load(key, options = {})
        @backend.transaction(true) { @backend[key] }
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @backend.transaction { @backend[key] = value }
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        @backend.transaction { @backend.delete(key) }
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @backend.transaction do
          value = Utils.to_int(@backend[key]) + amount
          @backend[key] = value.to_s
          value
        end
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        @backend.transaction do
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
        @backend.transaction do
          @backend.roots.each do |key|
            @backend.delete(key)
          end
        end
        self
      end

      protected

      def new_store(options)
        if RUBY_VERSION > '1.9'
          ::PStore.new(options[:file], options[:threadsafe])
        else
          ::PStore.new(options[:file])
        end
      end
    end
  end
end
