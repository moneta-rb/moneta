require 'pstore'

module Moneta
  module Adapters
    # PStore backend
    # @api public
    class PStore < Base
      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :file - PStore file
      def initialize(options = {})
        raise ArgumentError, 'Option :file is required' unless options[:file]
        FileUtils.mkpath(::File.dirname(options[:file]))
        @pstore = new_store(options)
      end

      def key?(key, options = {})
        @pstore.transaction(true) { @pstore.root?(key) }
      end

      def load(key, options = {})
        @pstore.transaction(true) { @pstore[key] }
      end

      def store(key, value, options = {})
        @pstore.transaction { @pstore[key] = value }
      end

      def delete(key, options = {})
        @pstore.transaction { @pstore.delete(key) }
      end

      def increment(key, amount = 1, options = {})
        @pstore.transaction do
          value = @pstore[key]
          intvalue = value.to_i
          raise 'Tried to increment non integer value' unless value == nil || intvalue.to_s == value.to_s
          intvalue += amount
          @pstore[key] = intvalue.to_s
          intvalue
        end
      end

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
