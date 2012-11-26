require 'hashery/lru_hash'

module Juno
  module Adapters
    class LRUHash < Memory
      def initialize(options = {})
        @memory = Hashery::LRUHash.new(options[:max_size] || 1024)
      end
    end
  end
end
