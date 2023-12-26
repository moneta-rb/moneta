module Moneta
  module Transforms
    # Encodes string using quoted-printable MIME encoding, as described in
    # {https://docs.ruby-lang.org/en/3.2/packed_data_rdoc.html#label-Other+String+Directives}
    class QP < Transform
      # Encodes to quoted-printable format
      #
      # @param value [String]
      # @return [String]
      def encode(value)
        [value].pack("M")
      end

      # Decodes from quoted-printable format
      #
      # @param value [String]
      # @return [String]
      def decode(value)
        value.unpack1("M")
      end
    end
  end
end
