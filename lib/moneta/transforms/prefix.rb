module Moneta
  module Transforms
    # Prefixes strings
    class Prefix < Transform
      # @param prefix [String] The prefix to add
      def initialize(prefix:, **options)
        super

        raise "prefix must be a string" unless prefix.is_a? String
        @prefix = prefix
      end

      # Checks that the string starts with the prefix
      #
      # @param value [String]
      # @return [Boolean]
      def encoded?(value)
        value.start_with?(@prefix)
      end

      # Prepends the prefix
      #
      # @param value [String] The string to prefix
      # @return [String] The +value+ with the prefix prepended
      def encode(value)
        @prefix + value
      end

      # Removes the prefix
      #
      # @param value [String] The prefixed string
      # @return [String] The +value+ with the prefix removed
      def decode(value)
        raise "value is not prefixed with #{@prefix}" unless encoded? value
        value[@prefix.length..]
      end
    end
  end
end
