require 'cityhash'

module Moneta
  module Transforms
    class City32 < Transform
      encode do |value|
        ::CityHash.hash32(value).to_s(16)
      end
    end
  end
end
