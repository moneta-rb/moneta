require 'dbm'

module Moneta
  module Adapters
    # DBM backend (Berkeley DB)
    # @api public
    class DBM
      include Defaults
      include DBMAdapter
      include IncrementSupport
      include CreateSupport
      include EachKeySupport

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
    end
  end
end
