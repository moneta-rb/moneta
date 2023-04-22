require 'base64'

module Moneta
  module Transforms
    # Encodes text as Base64 using the stdlib +base64+ library
    class Base64 < Transform
      def initialize(url_safe: false, strict: false, **options)
        super

        raise "Cannot use strict and url_safe together" if url_safe && strict
        @url_safe = url_safe
        @strict = strict
      end

      def encode(value)
        if @url_safe
          ::Base64.urlsafe_encode64(value)
        elsif @strict
          ::Base64.strict_encode64(value)
        else
          ::Base64.encode64(value)
        end
      end

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
