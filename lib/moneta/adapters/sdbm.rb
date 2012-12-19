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
        @memory = ::SDBM.new(options[:file])
      end

      def close
        @memory.close
        nil
      end

      def store(key, value, options = {})
        super
        value
      rescue SDBMError
        # SDBM is not very robust!
        # You shouldn't put to much data into it, otherwise
        # it might raise a SDBMError.
        value
      end
    end
  end
end
