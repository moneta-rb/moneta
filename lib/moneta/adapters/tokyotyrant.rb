begin
  # Native client
  require 'tokyo_tyrant'
rescue LoadError
  # Ruby client
  require 'tokyotyrant'
end

module Moneta
  module Adapters
    # TokyoTyrant backend
    # @api public
    class TokyoTyrant < Adapter
      include HashAdapter

      # error code: no record found
      ENOREC = 7

      supports :create, :increment

      backend do |host: '127.0.0.1', port: 1978|
        if defined?(::TokyoTyrant::RDB)
          # Use ruby client
          ::TokyoTyrant::RDB.new.tap do |backend|
            backend.open(host, port) or raise backend.errmsg
          end
        else
          # Use native client
          ::TokyoTyrant::DB.new(host, port)
        end
      end

      # @param [Hash] options
      # @option options [String] :host ('127.0.0.1') Server host name
      # @option options [Integer] :port (1978) Server port
      # @option options [::TokyoTyrant::RDB] :backend Use existing backend instance
      def initialize(options = {})
        super
        @native = backend.class.name != 'TokyoTyrant::RDB'
        probe = '__tokyotyrant_endianness_probe'
        backend.delete(probe)
        backend.addint(probe, 1)
        @pack = backend.delete(probe) == [1].pack('l>') ? 'l>' : 'l<'
      end

      # (see Proxy#load)
      def load(key, options = {})
        value = backend[key]
        # raise if there is an error and the error is not "no record"
        error if value == nil && backend.ecode != ENOREC
        value && unpack(value)
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        backend.put(key, pack(value)) or error
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = load(key, options)
        if value
          backend.delete(key) or error
          value
        end
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        backend.addint(key, amount) or error
      end

      # (see Proxy#create)
      def create(key, value, options = {})
        if @native
          begin
            # Native client throws an exception
            backend.putkeep(key, pack(value))
          rescue TokyoTyrantError
            false
          end
        else
          backend.putkeep(key, pack(value))
        end
      end

      # (see Proxy#close)
      def close
        backend.close
        nil
      end

      # (see Proxy#slice)
      def slice(*keys, **options)
        hash =
          if @native
            backend.mget(*keys)
          else
            hash = Hash[keys.map { |key| [key] }]
            raise unless backend.mget(hash) >= 0
            hash
          end

        hash.each do |key, value|
          hash[key] = unpack(value)
        end
      end

      # (see Proxy#values_at)
      def values_at(*keys, **options)
        hash = slice(*keys, **options)
        keys.map { |key| hash[key] }
      end

      private

      def pack(value)
        intvalue = value.to_i
        if intvalue >= 0 && intvalue <= 0xFFFFFFFF && intvalue.to_s == value
          # Pack as 4 byte integer
          [intvalue].pack(@pack)
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
          value.unpack(@pack).first.to_s
        elsif value.bytesize >= 5 && value[-1] == ?\0
          # Remove nul character
          value[0..-2]
        else
          value
        end
      end

      def error
        raise "#{backend.class.name} error: #{backend.errmsg}"
      end
    end
  end
end
