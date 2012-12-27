require 'sdbm'

module Moneta
  module Adapters
    # SDBM backend
    # @api public
    class SDBM < Memory
      # @param [Hash] options
      # @option options [String] :file Database file
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
