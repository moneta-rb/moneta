module Moneta
  module Adapters
    # LRUHash backend
    #
    # Based on Hashery::LRUHash but simpler and measures both memory usage and hash size.
    #
    # @api public
    class LRUHash
      include Defaults
      include IncrementSupport
      include CreateSupport

      # @param [Hash] options
      # @option options [Integer] :max_size (1024000) Maximum byte size of all values
      # @option options [Integer] :max_value (options[:max_size]) Maximum byte size of one value
      # @option options [Integer] :max_count (10240) Maximum number of values
      def initialize(options = {})
        @max_size = options[:max_size] || 1024000
        @max_count = options[:max_count] || 10240
        @max_value = options[:max_value] || @max_size
        clear
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @entry.key?(key)
      end

      # (see Proxy#load)
      def load(key, options = {})
        if entry = @entry[key]
          entry.insert_after(@list)
          entry.value
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        if value.bytesize > @max_value
          delete(key)
        else
          if entry = @entry[key]
            @size -= entry.value.bytesize
          else
            @entry[key] = entry = Entry.new
            entry.key = key
          end
          entry.value = value
          @size += entry.value.bytesize
          entry.insert_after(@list)
          delete(@list.prev.key) while @list.next != @list.prev && (@size > @max_size || @entry.size > @max_count)
        end
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        if entry = @entry.delete(key)
          @size -= entry.value.bytesize
          entry.unlink
          entry.value
        end
      end

      # (see Proxy#clear)
      def clear(options = {})
        @entry, @size = {}, 0
        @list = Entry.new
        @list.prev = @list.next = @list
        self
      end

      private

      class Entry
        attr_accessor :key, :value, :prev, :next

        def unlink
          @prev.next = @next if @prev
          @next.prev = @prev if @next
          @prev = @next = nil
        end

        def insert_after(entry)
          if entry.next != self
            unlink
            @next = entry.next
            @prev = entry
            entry.next.prev = self
            entry.next = self
          end
        end
      end
    end
  end
end
