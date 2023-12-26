module Moneta
  module Transforms
    # Serializes objects to strings by calling their +#inspect+ methods.  All objects implement this method, but with quite different behaviours!
    class Inspect < Transform
      # @param value [Object]
      # @return [String]
      def encode(value)
        value.inspect
      end
    end
  end
end
