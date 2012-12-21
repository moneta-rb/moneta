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
        @hash = ::LevelDB::DB.new(options[:dir])
      end

      def key?(key, options = {})
        @hash.includes?(key)
      end

      def clear(options = {})
        @hash.each {|k,v| delete(k, options) }
        self
      end

      def close
        @hash.close
        nil
      end
    end
  end
end
