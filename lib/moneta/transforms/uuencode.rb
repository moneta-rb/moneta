module Moneta
  module Transforms
    class UUEncode < Transform
      def encode(value)
        [value].pack('u')
      end

      def decode(value)
        value.unpack1('u')
      end
    end
  end
end
