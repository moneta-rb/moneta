require "msgpack"

module Moneta
  module Transforms
    # Serializes objects to binary strings using the {https://rubygems.org/gems/msgpack msgpack gem}
    class MessagePack < Transform::Serializer
      delegate_to ::MessagePack
    end
  end
end
