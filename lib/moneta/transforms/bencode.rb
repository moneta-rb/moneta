require 'bencode'

module Moneta
  module Transforms
    class BEncode < Transform
      def encode(value)
        ::BEncode.dump(value)
      end

      def decode(value)
        # BEncode needs a mutable string
        ::BEncode.load(value.dup)
      end
    end
  end
end
