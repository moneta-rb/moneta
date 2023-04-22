require "openssl"

module Moneta
  module Transforms
    # Prepends an HMAC digest to the string. This requires a +secret+ to be provided.
    #
    # You may wish to additionally encode the combined string using {Base64}, {Hex}, etc.
    class HMAC < Transform

      # @param secret [String]
      # @param algorithm [String] Any algorithm understood by +OpenSSL::Digest+ can be used
      def initialize(secret:, algorithm: "sha256", **options)
        super

        @digest = OpenSSL::Digest.new(algorithm)
        @secret = secret
      end

      # Hashes the +value+ using HMAC, and returns the hash plus the original string concatenated
      #
      # @param value [String]
      # @return [String] HMAC followed by the original string
      def encode(value)
        OpenSSL::HMAC.digest(@digest, @secret, value) << value
      end

      # Verifies the digest at the start of the string using the secret
      #
      # @param value [String]
      # @return [Boolean]
      def encoded?(value)
        hash = value.byteslice(0, @digest.digest_length)
        rest = value.byteslice(@digest.digest_length..-1)
        hash == OpenSSL::HMAC.digest(@digest, @secret, rest)
      end

      # Verifies the digest and returns the original string if valid
      #
      # @param value [String]
      # @return [String]
      def decode(value)
        raise "value does not have correct HMAC" unless encoded? value
        value.byteslice(@digest.digest_length..-1)
      end
    end
  end
end
