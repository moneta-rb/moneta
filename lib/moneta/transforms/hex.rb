module Moneta
  module Transforms
    class Hex < Transform
      def encode(value)
        value.unpack('H*').first
      end

      def decode(value)
        [value].pack('H*')
      end
    end
  end
end
