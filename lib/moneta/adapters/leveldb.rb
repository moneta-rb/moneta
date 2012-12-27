require 'leveldb'

module Moneta
  module Adapters
    # LevelDB backend
    # @api public
    class LevelDB < Memory
      # @param [Hash] options
      # @option options [String] :dir - Database path
      # @option options All other options passed to `LevelDB::DB#new`
      def initialize(options = {})
        raise ArgumentError, 'Option :dir is required' unless options[:dir]
        @hash = ::LevelDB::DB.new(options[:dir])
      end

      # @see Proxy#key?
      def key?(key, options = {})
        @hash.includes?(key)
      end

      # @see Proxy#clear
      def clear(options = {})
        @hash.each {|k,v| delete(k, options) }
        self
      end

      # @see Proxy#close
      def close
        @hash.close
        nil
      end
    end
  end
end
