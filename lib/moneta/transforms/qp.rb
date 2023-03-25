module Moneta
  module Transforms
    class QP < Transform
      def encode(value)
        value.unpack('M').first
      end

      def decode(value)
        [value].pack('M')
      end
    end
  end
end
