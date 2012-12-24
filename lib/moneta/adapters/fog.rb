require 'fog'

module Moneta
  module Adapters
    # Fog backend (Cloud storage services)
    # @api public
    class Fog
      include Defaults

      # Constructor
      #
      # @param [Hash] options
      # @option options [String] :dir Fog directory
      # @option options Other options passed to `Fog::Storage#new`
      def initialize(options = {})
        raise ArgumentError, 'Option :dir is required' unless dir = options.delete(:dir)
        storage = ::Fog::Storage.new(options)
        @directory = storage.directories.create(:key => dir)
      end

      def key?(key, options = {})
        @directory.files.head(key) != nil
      end

      def load(key, options = {})
        value = @directory.files.get(key)
        value && value.body
      end

      def delete(key, options = {})
        if value = @directory.files.get(key)
          body = value.body
          value.destroy
          body
        end
      end

      def store(key, value, options = {})
        @directory.files.create(:key => key, :body => value)
        value
      end

      def clear(options = {})
        @directory.files.all.each do |file|
          file.destroy
        end
        self
      end
    end
  end
end
