module Moneta
  module Transforms
    class ToS < Transform
      def encode(value)
        value.to_s
      end
    end
  end
end
