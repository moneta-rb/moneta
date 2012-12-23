require 'sdbm'

module Moneta
  module Adapters
    # SDBM backend
    # @api public
    class SDBM < Memory
      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :file - Database file
      def initialize(options = {})
        raise ArgumentError, 'Option :file is required' unless options[:file]
        @hash = ::SDBM.new(options[:file])
      end

      def close
        @hash.close
        nil
      end
    end
  end
end
