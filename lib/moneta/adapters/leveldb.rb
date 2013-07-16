require 'leveldb'

module Moneta
  module Adapters
    # LevelDB backend
    # @api public
    class LevelDB < Memory
      # @param [Hash] options
      # @option options [String] :dir - Database path
      # @option options All other options passed to `LevelDB::DB#new`
      # @option options [::LevelDB::DB] :backend Use existing backend instance
      def initialize(options = {})
        @backend = options[:backend] ||
          begin
            raise ArgumentError, 'Option :dir is required' unless options[:dir]
            ::LevelDB::DB.new(options[:dir])
          end
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @backend.includes?(key)
      end

      # (see Proxy#clear)
      def clear(options = {})
        @backend.each {|k,v| delete(k, options) }
        self
      end

      # (see Proxy#close)
      def close
        @backend.close
        nil
      end
    end
  end
end
