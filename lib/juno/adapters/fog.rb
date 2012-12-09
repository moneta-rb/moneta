require 'fog'

module Juno
  module Adapters
    # Fog backend (Cloud storage services)
    # @api public
    class Fog < Base
      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :dir - Fog directory
      # * Other options passed to Fog::Storage#new
      def initialize(options = {})
        raise 'Option :dir is required' unless dir = options.delete(:dir)
        storage = ::Fog::Storage.new(options)
        @directory = storage.directories.create(:key => dir)
      end

      def key?(key, options = {})
        !!@directory.files.head(key)
      end

      def load(key, options = {})
        value = @directory.files.get(key)
        value ? value.body : nil
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
