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

      DEFAULT_MAX_SIZE = 1024000
      DEFAULT_MAX_COUNT = 10240

      # @param [Hash] options
      # @option options [Integer] :max_size (1024000) Maximum byte size of all values, nil disables the limit
      # @option options [Integer] :max_value (options[:max_size]) Maximum byte size of one value, nil disables the limit
      # @option options [Integer] :max_count (10240) Maximum number of values, nil disables the limit
      def initialize(options = {})
        @max_size = options.fetch(:max_size) { DEFAULT_MAX_SIZE }
        @max_count = options.fetch(:max_count) { DEFAULT_MAX_COUNT }
        @max_value = [options[:max_value], @max_size].compact.min
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
        if @max_value && value.bytesize > @max_value
          delete(key)
        else
          if entry = @entry[key]
            @size -= entry.value.bytesize if @max_size
          else
            @entry[key] = entry = Entry.new
            entry.key = key
          end
          entry.value = value
          @size += entry.value.bytesize if @max_size
          entry.insert_after(@list)
          delete(@list.prev.key) while @list.next != @list.prev && (@max_size && @size > @max_size || @max_count && @entry.size > @max_count)
        end
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        if entry = @entry.delete(key)
          @size -= entry.value.bytesize if @max_size
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
