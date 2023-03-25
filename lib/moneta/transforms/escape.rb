module Moneta
  module Transforms
    class Escape < Transform
      def encode(value)
        value.gsub(/[^a-zA-Z0-9_-]+/) { |match| '%' + match.unpack('H2' * match.bytesize).join('%').upcase }
      end

      def decode(value)
        value.gsub(/(?:%[0-9a-fA-F]{2})+/) { |match| [match.delete('%')].pack('H*') }
      end
    end
  end
end
