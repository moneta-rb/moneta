require 'localmemcache'

module Juno
  module Adapters
    # LocalMemCache backend
    # @api public
    class LocalMemCache < Memory
      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :file - Database file
      def initialize(options = {})
        raise 'No option :file specified' unless options[:file]
        @memory = ::LocalMemCache.new(:filename => options[:file])
      end

      def delete(key, options = {})
        value = load(key, options)
        @memory.delete(key)
        value
      end
    end
  end
end
