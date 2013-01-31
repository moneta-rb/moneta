require 'tokyotyrant'

module Moneta
  module Adapters
    # TokyoTyrant backend
    # @api public
    class TokyoTyrant
      include Defaults

      supports :create, :increment

      # @param [Hash] options
      # @option options [String] :host ('127.0.0.1') Server host name
      # @option options [Integer] :port (1978) Server port
      def initialize(options = {})
        options[:host] ||= '127.0.0.1'
        options[:port] ||=  1978
        @db = ::TokyoTyrant::RDB.new
        @db.open(options[:host], options[:port]) or raise @db.errmsg(@db.ecode)
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @db.has_key?(key)
      end

      # (see Proxy#load)
      def load(key, options = {})
        value = @db[key]
        value && unpack(value)
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @db[key] = pack(value)
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = load(key, options)
        if value
          @db.delete(key)
          unpack(value)
        end
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        @db.addint(key, amount) || raise('Tried to increment non integer value')
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        @db.putkeep(key, pack(value))
      end

      # (see Proxy#clear)
      def clear(options = {})
        @db.clear
        self
      end

      # (see Proxy#close)
      def close
        @db.close
        nil
      end

      private

      def pack(value)
        intvalue = value.to_i
        if intvalue >= 0 && intvalue <= 0xFFFFFFFF && intvalue.to_s == value
          # Pack as 4 byte integer
          [intvalue].pack('i')
        elsif value.bytesize >= 4
          # Add nul character to make value distinguishable from integer
          value + "\0"
        else
          value
        end
      end

      def unpack(value)
        if value.bytesize == 4
          # Unpack 4 byte integer
          value.unpack('i').first.to_s
        elsif value.bytesize >= 5 && value[-1] == ?\0
          # Remove nul character
          value[0..-2]
        else
          value
        end
      end
    end
  end
end
