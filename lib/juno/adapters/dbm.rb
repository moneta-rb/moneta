require 'dbm'

module Juno
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
        raise 'No option :file specified' unless options[:file]
        @memory = ::DBM.new(options[:file])
      end

      def close
        @memory.close
        nil
      end
    end
  end
end
