require 'hashery/lru_hash'

module Juno
  module Adapters
    # LRUHash backend
    # @api public
    class LRUHash < Memory
      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :max_size - Maximum size of hash (default 1024)
      def initialize(options = {})
        @memory = Hashery::LRUHash.new(options[:max_size] || 1024)
      end
    end
  end
end
