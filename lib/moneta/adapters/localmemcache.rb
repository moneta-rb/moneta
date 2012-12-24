require 'localmemcache'

module Moneta
  module Adapters
    # LocalMemCache backend
    # @api public
    class LocalMemCache
      include Defaults
      include HashAdapter

      # Constructor
      #
      # @param [Hash] options
      # @option options [String] :file Database file
      def initialize(options = {})
        raise ArgumentError, 'Option :file is required' unless options[:file]
        @hash = ::LocalMemCache.new(:filename => options[:file])
      end

      def delete(key, options = {})
        value = load(key, options)
        @hash.delete(key)
        value
      end
    end
  end
end
