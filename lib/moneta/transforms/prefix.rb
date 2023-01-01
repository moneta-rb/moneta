module Moneta
  module Transforms
    class Prefix < Transform
      def initialize(prefix:, **options)
        super(decodable: true)

        raise "prefix must be a string" unless prefix.is_a? String
        @prefix = prefix
      end

      def encoded?(value)
        value.start_with?(@prefix)
      end

      def encode(value)
        @prefix + value
      end

      def decode(value)
        raise "value is not prefixed with #{@prefix}" unless encoded? value
        value[@prefix.length..-1]
      end
    end
  end
end
