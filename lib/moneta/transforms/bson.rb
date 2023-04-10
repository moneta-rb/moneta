require 'bson'

module Moneta
  module Transforms
    class BSON < Transforms::Serializer
      def serialize(value)
        ::BSON::Document['v' => value].to_bson.to_s
      end

      def deserialize(value)
        ::BSON::Document.from_bson(::BSON::ByteBuffer.new(value))['v']
      end
    end
  end
end
