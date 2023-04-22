require "digest/sha2"

module Moneta
  module Transforms
    # Hashes strings using SHA-256, encoded as a hex string (64 bytes)
    class SHA256 < Transform
      delegate_to ::Digest::SHA256, %i[hexdigest]
    end
  end
end
