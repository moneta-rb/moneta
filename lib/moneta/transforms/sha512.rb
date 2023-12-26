require "digest/sha2"

module Moneta
  module Transforms
    # Hashes strings using SHA-512, encoded as a hex string (128 bytes)
    class SHA512 < Transform
      delegate_to ::Digest::SHA512, %i[hexdigest]
    end
  end
end
