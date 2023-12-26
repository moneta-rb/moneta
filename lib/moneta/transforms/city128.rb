require "cityhash"

module Moneta
  module Transforms
    # Hashes strings using the {https://rubygems.org/gems/cityhash cityhash gem} - 128 bit version
    class City128 < Transform
      # Hashes using the +CityHash128+ algorithm
      #
      # @param [String]
      # @return [String]
      def encode(value)
        ::CityHash.hash128(value).to_s(16)
      end
    end
  end
end
