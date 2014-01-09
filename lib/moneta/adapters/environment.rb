module Moneta
  module Adapters
    # Memory backend using a hash to store the entries
    # @api public
    class Environment
      include Defaults
      include HashAdapter
      include IncrementSupport

      # @param [Hash] options Options hash
      # @option options [Hash] :backend Use existing backend instance
      def initialize(options = {})
        @backend = options[:backend] || ENV
      end
    end
  end
end
