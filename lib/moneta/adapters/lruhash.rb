module Moneta
  module Adapters
    # LRUHash backend
    #
    # Based on Hashery::LRUHash but simpler and measures memory usage instead of hash size.
    #
    # @api public
    class LRUHash < Base
      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :max_size - Maximum byte size of hash values (default 1024000)
      def initialize(options = {})
        @max_size = options[:max_size] || 1024000
        clear
      end

      def key?(key, options = {})
        @entry.key?(key)
      end

      def load(key, options = {})
        if entry = @entry[key]
          entry.insert_after(@list)
          entry.value
        end
      end

      def store(key, value, options = {})
        if entry = @entry[key]
          @size -= entry.value.bytesize
        else
          @entry[key] = entry = Entry.new
          entry.key = key
        end
        entry.value = value
        @size += entry.value.bytesize
        entry.insert_after(@list)
        delete(@list.prev.key) while @list.next != @list.prev && @size > @max_size
        value
      end

      def delete(key, options = {})
        if entry = @entry.delete(key)
          @size -= entry.value.bytesize
          entry.unlink
          entry.value
        end
      end

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
