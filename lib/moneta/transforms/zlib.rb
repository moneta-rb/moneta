require 'zlib'

module Moneta
  module Transforms
    class Zlib < Transform
      def encode(value)
        ::Zlib::Deflate.deflate(value)
      end

      def decode(value)
        ::Zlib::Inflate.inflate(value)
      end
    end
  end
end
