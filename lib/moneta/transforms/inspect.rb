module Moneta
  module Transforms
    class Inspect < Transform
      def encode(value)
        value.inspect
      end
    end
  end
end
