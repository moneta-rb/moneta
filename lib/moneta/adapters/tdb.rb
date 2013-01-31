require 'tdb'

module Moneta
  module Adapters
    # TDB backend
    # @api public
    class TDB < Memory
      # @param [Hash] options
      # @option options [String] :file Database file
      def initialize(options)
        @backend = options[:backend] ||
          begin
            raise ArgumentError, 'Option :file is required' unless file = options.delete(:file)
            ::TDB.new(file, options)
          end
      end

      # (see Proxy#close)
      def close
        @backend.close
        nil
      end
    end
  end
end
