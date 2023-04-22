module Moneta
  module Transforms
    # Encodes text in {https://pubs.opengroup.org/onlinepubs/9699919799/utilities/uuencode.html uuencode (historical)
    # format}.  The encoded text lacks the +begin+ and +end+ lines.
    class UUEncode < Transform
      # @param value [String]
      # @return [String]
      def encode(value)
        [value].pack("u")
      end

      # @param value [String]
      # @return [String]
      def decode(value)
        value.unpack1("u")
      end
    end
  end
end
