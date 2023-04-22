require "bson"

module Moneta
  module Transforms
    # Serializes objects to binary strings using the {https://rubygems.org/gems/bson bson gem}
    class BSON < Transforms::Serializer
      # Serialize to BSON
      #
      # @param value [Object]
      # @return [String]
      def serialize(value)
        ::BSON::Document["v" => value].to_bson.to_s
      end

      # Deserialize from BSON
      #
      # @param value [String]
      # @return [Object]
      def deserialize(value)
        ::BSON::Document.from_bson(::BSON::ByteBuffer.new(value))["v"]
      end
    end
  end
end
