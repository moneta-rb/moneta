module Moneta
  module Transforms
    # Encodes strings using {https://datatracker.ietf.org/doc/html/rfc1738 RFC 1738} %-escaping
    class Escape < Transform
      # Escapes characters in the given string except for alphanum, "-" and "_".
      #
      # @param value [String]
      # @return [String]
      def encode(value)
        value.gsub(/[^a-zA-Z0-9_-]+/) { |match| "%#{match.unpack("H2" * match.bytesize).join("%").upcase}" }
      end

      # Unescapes any characters %-encoded characters in the string
      #
      # @param value [String]
      # @return [String]
      def decode(value)
        value.gsub(/(?:%[0-9a-fA-F]{2})+/) { |match| [match.delete("%")].pack("H*") }
      end
    end
  end
end
