require 'fog/storage'

module Moneta
  module Adapters
    # Fog backend (Cloud storage services)
    # @api public
    class Fog
      include Defaults

      attr_reader :backend

      # @param [Hash] options
      # @option options [String] :dir Fog directory
      # @option options [::Fog::Storage] :backend Use existing backend instance
      # @option options Other options passed to `Fog::Storage#new`
      def initialize(options = {})
        raise ArgumentError, 'Option :dir is required' unless dir = options.delete(:dir)
        @backend = options[:backend] || ::Fog::Storage.new(options)
        @directory = @backend.directories.get(dir) || @backend.directories.create(:key => dir)
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @directory.files.head(key) != nil
      end

      # (see Proxy#load)
      def load(key, options = {})
        value = @directory.files.get(key)
        value && value.body
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        if value = @directory.files.get(key)
          body = value.body
          value.destroy
          body
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        value = value.dup if value.frozen? # HACK: Fog needs unfrozen string
        @directory.files.create(options.merge(:key => key, :body => value))
        value
      end

      # (see Proxy#clear)
      def clear(options = {})
        @directory.files.all.each do |file|
          file.destroy
        end
        self
      end
    end
  end
end
