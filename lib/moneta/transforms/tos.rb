module Moneta
  module Transforms
    # Serializes objects to strings by calling their +#to_s+ method.  This
    # method is implemented on all(?) objects, but with wildly different
    # results!
    class ToS < Transform
      # @param value [Object]
      # @return [String]
      def encode(value)
        value.to_s
      end
    end
  end
end
