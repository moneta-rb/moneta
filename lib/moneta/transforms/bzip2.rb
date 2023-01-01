require 'rbzip2'

module Moneta
  module Transforms
    class Bzip2 < Transform
      encode do |value|
        io = ::StringIO.new
        bz = ::RBzip2.default_adapter::Compressor.new(io)
        bz.write(value)
        bz.close
        io.string
      end

      decode do |value|
        ::RBzip2.default_adapter::Decompressor.new(::StringIO.new(value)).read
      end
    end
  end
end
