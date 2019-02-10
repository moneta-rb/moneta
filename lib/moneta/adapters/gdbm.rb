require 'gdbm'

module Moneta
  module Adapters
    # GDBM backend
    # @api public
    class GDBM
      include Defaults
      include DBMAdapter
      include IncrementSupport
      include CreateSupport
      include EachKeySupport

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
    end
  end
end
