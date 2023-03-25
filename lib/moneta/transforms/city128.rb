require 'cityhash'

module Moneta
  module Transforms
    class City128 < Transform
      def encode(value)
        ::CityHash.hash128(value).to_s(16)
      end
    end
  end
end
