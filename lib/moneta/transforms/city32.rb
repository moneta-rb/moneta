require "cityhash"

module Moneta
  module Transforms
    # Hashes strings using the {https://rubygems.org/gems/cityhash cityhash gem} - 32 bit version
    class City32 < Transform
      # Hashes using the +CityHash32+ algorithm
      #
      # @param [String]
      # @return [String]
      def encode(value)
        ::CityHash.hash32(value).to_s(16)
      end
    end
  end
end
