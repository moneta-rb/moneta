require 'dbm'

module Moneta
  module Adapters
    # DBM backend (Berkeley DB)
    # @api public
    class DBM < Memory
      # @param [Hash] options
      # @option options [String] :file Database file
      # @option options [::DBM] :backend Use existing backend instance
      def initialize(options = {})
        @backend = options[:backend] ||
          begin
            raise ArgumentError, 'Option :file is required' unless options[:file]
            ::DBM.new(options[:file])
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
