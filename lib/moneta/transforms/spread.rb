module Moneta
  module Transforms
    class Spread < Transform
      def encode(value)
        ::File.join(value[0..1], value [2..-1])
      end
    end
  end
end
