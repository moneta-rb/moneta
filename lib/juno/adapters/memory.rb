module Juno
  module Adapters
    class Memory < Base
      def initialize(options = {})
        @memory = {}
      end

      def key?(key, options = {})
        @memory.has_key?(key)
      end

      def load(key, options = {})
        @memory[key]
      end

      def store(key, value, options = {})
        @memory[key] = value
      end

      def delete(key, options = {})
        @memory.delete(key)
      end

      def clear(options = {})
        @memory.clear
        self
      end
    end
  end
end
