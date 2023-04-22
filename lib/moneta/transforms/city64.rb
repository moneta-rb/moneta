require "cityhash"

module Moneta
  module Transforms
    # Hashes strings using the {https://rubygems.org/gems/cityhash cityhash gem} - 64 bit version
    class City64 < Transform
      # Hashes using the +CityHash64+ algorithm
      #
      # @param [String]
      # @return [String]
      def encode(value)
        ::CityHash.hash64(value).to_s(16)
      end
    end
  end
end
