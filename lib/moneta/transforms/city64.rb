require 'cityhash'

module Moneta
  module Transforms
    class City64 < Transform
      encode do |value|
        ::CityHash.hash64(value).to_s(16)
      end
    end
  end
end
