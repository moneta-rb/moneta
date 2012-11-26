require 'hashery/lru_hash'

module Juno
  module Adapters
    class LRUHash < Memory
      def initialize(options = {})
        raise 'No option :max_size specified' unless options[:max_size]
        @memory = Hashery::LRUHash.new(options[:max_size])
      end
    end
  end
end
