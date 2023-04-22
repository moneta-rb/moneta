module Moneta
  module Transforms
    # Encodes strings using {https://datatracker.ietf.org/doc/html/rfc1738 RFC 1738} %-escaping, commonly used in URL query strings.
    #
    # @example
    #   transform = Moneta::Transforms::Escape.new
    #   string = 'This "string", containing punctuation?'
    #   transform.encode(string) # => "This%20%22string%22%2C%20containing%20punctuation%3F"
    class Escape < Transform
      # Escapes characters in the given string except for alphanum, "-" and "_".
      #
      # @param value [String]
      # @return [String]
      def encode(value)
        value.gsub(/[^a-zA-Z0-9_-]+/) do |match|
          "%#{match.unpack('H2' * match.bytesize).join('%').upcase}"
        end
      end

      # Unescapes any characters %-encoded characters in the string
      #
      # @param value [String]
      # @return [String]
      def decode(value)
        value.gsub(/(?:%[0-9a-fA-F]{2})+/) do |match|
          [match.delete("%")].pack("H*")
        end
      end
    end
  end
end
