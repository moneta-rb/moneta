require 'pstore'

module Moneta
  module Adapters
    # PStore backend
    # @api public
    class PStore
      include Defaults

      supports :create, :increment

      # @param [Hash] options
      # @option options [String] :file PStore file
      def initialize(options = {})
        raise ArgumentError, 'Option :file is required' unless options[:file]
        FileUtils.mkpath(::File.dirname(options[:file]))
        @pstore = new_store(options)
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @pstore.transaction(true) { @pstore.root?(key) }
      end

      # (see Proxy#load)
      def load(key, options = {})
        @pstore.transaction(true) { @pstore[key] }
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @pstore.transaction { @pstore[key] = value }
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        @pstore.transaction { @pstore.delete(key) }
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @pstore.transaction do
          value = Utils.to_int(@pstore[key]) + amount
          @pstore[key] = value.to_s
          value
        end
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        @pstore.transaction do
          if @pstore.root?(key)
            false
          else
            @pstore[key] = value
            true
          end
        end
      end

      # (see Proxy#clear)
      def clear(options = {})
        @pstore.transaction do
          @pstore.roots.each do |key|
            @pstore.delete(key)
          end
        end
        self
      end

      protected

      if RUBY_VERSION > '1.9'
        def new_store(options)
          ::PStore.new(options[:file], options[:threadsafe])
        end
      else
        def new_store(options)
          ::PStore.new(options[:file])
        end
      end
    end
  end
end
