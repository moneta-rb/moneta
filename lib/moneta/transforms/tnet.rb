require "tnetstring"

module Moneta
  module Transforms
    # Serializes objects to strings using the {https://rubygems.org/gems/tnetstring tnetstring gem}.
    #
    # @see https://tnetstrings.info/
    class TNet < Transform::Serializer
      # @param value [Object]
      # @return [String]
      def serialize(value)
        ::TNetstring.dump(value)
      end

      # @param value [String]
      # @return [Object]
      def deserialize(value)
        ::TNetstring.parse(value).first
      end
    end
  end
end
