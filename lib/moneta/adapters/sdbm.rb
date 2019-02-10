require 'sdbm'

module Moneta
  module Adapters
    # SDBM backend
    # @api public
    class SDBM
      include Defaults
      include DBMAdapter
      include IncrementSupport
      include CreateSupport
      include EachKeySupport

      # @param [Hash] options
      # @option options [String] :file Database file
      # @option options [::SDBM] :backend Use existing backend instance
      def initialize(options = {})
        @backend = options[:backend] ||
          begin
            raise ArgumentError, 'Option :file is required' unless options[:file]
            ::SDBM.new(options[:file])
          end
      end
    end
  end
end
