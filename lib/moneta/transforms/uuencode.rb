module Moneta
  module Transforms
    class UUEncode < Transform
      def encode(value)
        value.unpack('u').first
      end

      def decode(value)
        [value].pack('u')
      end
    end
  end
end
