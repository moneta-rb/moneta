require "rbzip2"
require "stringio"

module Moneta
  module Transforms
    # Compresses strings using the {https://rubygems.org/gems/rbzip2 rbzip2 gem}
    class Bzip2 < Transform
      # Compresses using BZip2
      #
      # @param value [String]
      # @return [String]
      def encode(value)
        io = ::StringIO.new
        bz = ::RBzip2.default_adapter::Compressor.new(io)
        bz.write(value)
        bz.close
        io.string
      end

      # Returns true if the string starts with the right magic number ("BZh")
      #
      # @param value [Object]
      # @return [Boolean]
      def encoded?(value)
        String === value && value.byteslice(0, 3) == "BZh"
      end

      # Decompresses BZip2-compressed data
      #
      # @param value [String]
      # @return [String]
      def decode(value)
        ::RBzip2.default_adapter::Decompressor.new(::StringIO.new(value)).read
      end
    end
  end
end
