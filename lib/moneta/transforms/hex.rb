module Moneta
  module Transforms
    class Hex < Transform
      encode do |value|
        value.unpack('H*').first
      end

      decode do |value|
        [value].pack('H*')
      end
    end
  end
end
