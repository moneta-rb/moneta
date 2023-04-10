require 'msgpack'

module Moneta
  module Transforms
    class MessagePack < Transform::Serializer
      delegate_to ::MessagePack
    end
  end
end
