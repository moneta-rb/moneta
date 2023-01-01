require 'openssl'

module Moneta
  module Transforms
    class HMAC < Transform
      def initialize(algorithm: 'sha256', secret:, **options)
        super(decodable: true)

        @digest = OpenSSL::Digest.new(algorithm)
        @secret = secret
      end

      def encode(value)
        OpenSSL::HMAC.digest(@digest, @secret, value) << value
      end

      def encoded?(value)
        hash = value.byteslice(0, @digest.digest_length)
        rest = value.byteslice(@digest.digest_length)
        hash == OpenSSL::HMAC.digest(@digest, @secret, rest)
      end

      def decode(value)
        raise "value does not have correct HMAC" unless encoded? value
        value.byteslice(@digest.digest_length)
      end
    end
  end
end
