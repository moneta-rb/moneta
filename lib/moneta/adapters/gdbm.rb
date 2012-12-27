require 'gdbm'

module Moneta
  module Adapters
    # GDBM backend
    # @api public
    class GDBM < Memory
      # @param [Hash] options
      # @option options [String] :file Database file
      def initialize(options = {})
        raise ArgumentError, 'Option :file is required' unless options[:file]
        @hash = ::GDBM.new(options[:file])
      end

      # (see Proxy#close)
      def close
        @hash.close
        nil
      end
    end
  end
end
