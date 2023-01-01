module Moneta
  module Transforms
    class QP < Transform
      encode do |value|
        value.unpack('M').first
      end

      decode do |value|
        [value].pack('M')
      end
    end
  end
end
