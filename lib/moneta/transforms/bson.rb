require 'bson'

module Moneta
  module Transforms
    class BSON < Transform
      def encode(value)
        ::BSON::Document['v' => value].to_bson.to_s
      end

      def decode(value)
        ::BSON::Document.from_bson(::BSON::ByteBuffer.new(value))['v']
      end
    end
  end
end
