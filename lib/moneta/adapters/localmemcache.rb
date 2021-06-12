require 'localmemcache'

module Moneta
  module Adapters
    # LocalMemCache backend
    # @api public
    class LocalMemCache < Adapter
      include HashAdapter

      # @!method initialize(options = {})
      #   @param [Hash] options
      #   @option options [String] :file Database file
      #   @option options [::LocalMemCache] :backend Use existing backend instance
      backend { |file:| ::LocalMemCache.new(filename: file) }

      # (see Proxy#delete)
      def delete(key, options = {})
        value = load(key, options)
        backend.delete(key)
        value
      end
    end
  end
end
