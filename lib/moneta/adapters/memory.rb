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
      def initialize(options = {})
        @hash = {}
      end
    end
  end
end
