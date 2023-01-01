require 'cityhash'

module Moneta
  module Transforms
    class City128 < Transform
      encode do |value|
        ::CityHash.hash128(value).to_s(16)
      end
    end
  end
end
