require 'bencode'

module Moneta
  module Transforms
    class BEncode < Transform::Serializer
      def serialize(value)
        ::BEncode.dump(value)
      end

      def deserialize(value)
        # BEncode needs a mutable string
        ::BEncode.load(value.dup).tap do |deserialized_value|
          raise "::BEncode.load returned nil" if deserialized_value == nil
        end
      end
    end
  end
end
