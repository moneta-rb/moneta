module Moneta
  module Transforms
    # Encodes the string as a string representation of the bytes in hexadecimal
    #
    # @example
    #   Moneta::Transforms::Hex.new.encode("Hello") # => "48656c6c6f"
    class Hex < Transform
      # Encodes to hexadecimal
      #
      # @param value [String]
      # @return [String]
      def encode(value)
        value.unpack1("H*")
      end

      # Decodes from hexadecimal
      #
      # @param value [String]
      # @return [String]
      def decode(value)
        [value].pack("H*")
      end
    end
  end
end
