module Moneta
  module Adapters
    # Memory backend using a hash to store the entries
    # @api public
    class Memory
      include Defaults
      include HashAdapter
      include IncrementSupport
      include CreateSupport

      # @param [Hash] options Options hash
      # @option options [Hash] :backend Use existing backend instance
      def initialize(options = {})
        @backend = options[:backend] || {}
      end
    end
  end
end
