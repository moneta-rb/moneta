module Moneta
  module Transforms
    class QP < Transform
      def encode(value)
        [value].pack('M')
      end

      def decode(value)
        value.unpack1('M')
      end
    end
  end
end
