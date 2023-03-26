module Moneta
  module Transforms
    class Hex < Transform
      def encode(value)
        value.unpack1('H*')
      end

      def decode(value)
        [value].pack('H*')
      end
    end
  end
end
