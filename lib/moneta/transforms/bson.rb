require 'bson'

module Moneta
  module Transforms
    class BSON < Transform
      encode do |value|
        ::BSON::Document['v' => value].to_bson.to_s
      end

      decode do |value|
        ::BSON::Document.from_bson(::BSON::ByteBuffer.new(value))['v']
      end
    end
  end
end
