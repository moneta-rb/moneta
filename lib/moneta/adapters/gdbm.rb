require 'gdbm'

module Moneta
  module Adapters
    # GDBM backend
    # @api public
    class GDBM < Memory
      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :file - Database file
      def initialize(options = {})
        raise ArgumentError, 'Option :file is required' unless options[:file]
        @hash = ::GDBM.new(options[:file])
      end

      def close
        @hash.close
        nil
      end
    end
  end
end
