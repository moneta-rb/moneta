module Moneta
  module Transforms
    class UUEncode < Transform
      encode do |value|
        value.unpack('u').first
      end

      decode do |value|
        [value].pack('u')
      end
    end
  end
end
