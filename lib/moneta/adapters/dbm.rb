require 'dbm'

module Moneta
  module Adapters
    # DBM backend (Berkeley DB)
    # @api public
    class DBM < Memory
      # @param [Hash] options
      # @option options [String] :file Database file
      def initialize(options = {})
        raise ArgumentError, 'Option :file is required' unless options[:file]
        @hash = ::DBM.new(options[:file])
      end

      # (see Proxy#close)
      def close
        @hash.close
        nil
      end
    end
  end
end
