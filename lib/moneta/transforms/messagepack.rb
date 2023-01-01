require 'msgpack'

module Moneta
  module Transforms
    class MessagePack < Transform
      delegate_to ::MessagePack
    end
  end
end
