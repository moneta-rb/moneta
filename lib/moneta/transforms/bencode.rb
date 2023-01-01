require 'bencode'

module Moneta
  module Transforms
    class BEncode < Transform
      encode do |value|
        ::BEncode.dump(value)
      end

      decode do |value|
        # BEncode needs a mutable string
        ::BEncode.load(value.dup)
      end
    end
  end
end
