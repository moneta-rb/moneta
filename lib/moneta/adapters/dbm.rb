require 'dbm'

module Moneta
  module Adapters
    # DBM backend (Berkeley DB)
    # @api public
    class DBM < Memory
      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :file - Database file
      def initialize(options = {})
        raise ArgumentError, 'Option :file is required' unless options[:file]
        @hash = ::DBM.new(options[:file])
      end

      def close
        @hash.close
        nil
      end
    end
  end
end
