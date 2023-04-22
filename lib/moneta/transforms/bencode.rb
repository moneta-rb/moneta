require "bencode"

module Moneta
  module Transforms
    # Serializes objects using the {https://github.com/dasch/ruby-bencode bencode gem}
    class BEncode < Transform::Serializer
      # (see Transform::Serializer#serialize)
      def serialize(value)
        ::BEncode.dump(value)
      end

      # (see Transform::Serializer#deserialize)
      def deserialize(value)
        # BEncode needs a mutable string
        ::BEncode.load(value.dup).tap do |deserialized_value|
          raise "::BEncode.load returned nil" if deserialized_value == nil
        end
      end
    end
  end
end
