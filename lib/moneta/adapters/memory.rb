module Moneta
  module Adapters
    # Memory backend using a hash to store the entries
    # @api public
    class Memory < Adapter
      include NilValues
      include HashAdapter
      include IncrementSupport
      include CreateSupport
      include EachKeySupport

      # @!method initialize(options = {})
      #   @param [Hash] options Options hash
      #   @option options [Hash] :backend Use existing backend instance
      backend { {} }
    end
  end
end
