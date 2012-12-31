require 'tdb'

module Moneta
  module Adapters
    # TDB backend
    # @api public
    class TDB < Memory
      # @param [Hash] options
      # @option options [String] :file Database file
      def initialize(options = {})
        raise ArgumentError, 'Option :file is required' unless file = options.delete(:file)
        @hash = ::TDB.new(file, options)
      end

      # (see Proxy#close)
      def close
        @hash.close
        nil
      end
    end
  end
end
