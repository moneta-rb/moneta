module Moneta
  module Transforms
    class Spread < Transform
      encode do |value|
        ::File.join(value[0..1], value [2..-1])
      end
    end
  end
end
