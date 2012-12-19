require 'leveldb'

module Moneta
  module Adapters
    # LevelDB backend
    # @api public
    class LevelDB < Memory
      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :dir - Database path
      # * All other options passed to LevelDB::DB#new
      def initialize(options = {})
        raise ArgumentError, 'Option :dir is required' unless options[:dir]
        @memory = ::LevelDB::DB.new(options[:dir])
      end

      def key?(key, options = {})
        @memory.includes?(key)
      end

      def clear(options = {})
        @memory.each {|k,v| delete(k, options) }
        self
      end

      def close
        @memory.close
        nil
      end
    end
  end
end
