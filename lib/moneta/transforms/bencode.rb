require 'bencode'

module Moneta
  module Transforms
    class BEncode < Transform::Serializer
      def serialize(value)
        ::BEncode.dump(value)
      end

      def deserialize(value)
        # BEncode needs a mutable string
        ::BEncode.load(value.dup)
      end
    end
  end
end
