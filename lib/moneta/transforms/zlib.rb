require 'zlib'

module Moneta
  module Transforms
    class Zlib < Transform
      encode do |value|
        ::Zlib::Deflate.deflate(value)
      end

      decode do |value|
        ::Zlib::Inflate.inflate(value)
      end
    end
  end
end
