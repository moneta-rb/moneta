require 'tnetstring'

module Moneta
  module Transforms
    class TNet < Transform::Serializer
      def serialize(value)
        ::TNetstring.dump(value)
      end

      def deserialize(value)
        ::TNetstring.parse(value).first
      end
    end
  end
end
