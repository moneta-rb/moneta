require "base64"

module Moneta
  module Transforms
    # Encodes text as Base64 using the stdlib +base64+ library
    class Base64 < Transform
      # @param url_safe [Boolean] If +true+, URL-safe base64 will be used instead.
      # @param strict [Boolean] By default the resulting string has line breaks in it.  Specifying
      #   +strict: true+ will remove line breaks.
      # @param padding [Boolean] This can be set to +false+ in conjuction with +url_safe: true+ to output unpadded
      #   URL-safe Base64
      def initialize(url_safe: false, strict: false, padding: true, **options)
        super

        raise "Cannot use strict and url_safe together" if url_safe && strict
        raise "padding: false is only valid with url_safe: true" if !padding && !url_safe

        @url_safe = url_safe
        @strict = strict
        @padding = padding
      end

      # Encode string to Base64
      #
      # @param value [String]
      # @return [String]
      def encode(value)
        if @url_safe
          ::Base64.urlsafe_encode64(value, padding: padding)
        elsif @strict
          ::Base64.strict_encode64(value)
        else
          ::Base64.encode64(value)
        end
      end

      # Decode from Base64
      #
      # @param value [String]
      # @return [String]
      def decode(value)
        if @url_safe
          ::Base64.urlsafe_decode64(value)
        elsif @strict
          ::Base64.strict_decode64(value)
        else
          ::Base64.decode64(value)
        end
      end
    end
  end
end
