require 'localmemcache'

module Moneta
  module Adapters
    # LocalMemCache backend
    # @api public
    class LocalMemCache
      include Defaults
      include HashAdapter

      # @param [Hash] options
      # @option options [String] :file Database file
      # @option options [::LocalMemCache] :backend Use existing backend instance
      def initialize(options = {})
        @backend = options[:backend] ||
          begin
            raise ArgumentError, 'Option :file is required' unless options[:file]
            ::LocalMemCache.new(:filename => options[:file])
          end
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = load(key, options)
        @backend.delete(key)
        value
      end
    end
  end
end
