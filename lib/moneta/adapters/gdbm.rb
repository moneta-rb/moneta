require 'gdbm'

module Moneta
  module Adapters
    # GDBM backend
    # @api public
    class GDBM < Memory
      # @param [Hash] options
      # @option options [String] :file Database file
      # @option options [::GDBM] :backend Use existing backend instance
      def initialize(options = {})
        @backend = options[:backend] ||
          begin
            raise ArgumentError, 'Option :file is required' unless options[:file]
            ::GDBM.new(options[:file])
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
