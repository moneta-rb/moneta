require 'leveldb'

module Moneta
  module Adapters
    # LevelDB backend
    # @api public
    class LevelDB < Adapter
      include HashAdapter
      include IncrementSupport
      include CreateSupport
      include EachKeySupport

      # @!method initialize(options = {})
      #   @param [Hash] options
      #   @option options [String] :dir - Database path
      #   @option options All other options passed to `LevelDB::DB#new`
      #   @option options [::LevelDB::DB] :backend Use existing backend instance
      backend { |dir:| ::LevelDB::DB.new(dir) }

      # (see Proxy#key?)
      def key?(key, options = {})
        backend.includes?(key)
      end

      # (see Proxy#clear)
      def clear(options = {})
        backend.each { |k,| delete(k, options) }
        self
      end

      # (see Proxy#close)
      def close
        backend.close
        nil
      end

      # (see Proxy#each_key)
      def each_key
        return enum_for(:each_key) { backend.size } unless block_given?
        backend.each { |key, _| yield key }
        self
      end

      # (see Proxy#values_at)
      def values_at(*keys, **options)
        ret = nil
        backend.batch { ret = super }
        ret
      end

      # (see Proxy#merge!)
      def merge!(*keys, **options)
        backend.batch { super }
        self
      end
    end
  end
end
