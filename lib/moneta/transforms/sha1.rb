require "digest/sha1"

module Moneta
  module Transforms
    # Hashes strings using SHA-1, encoded as a hex string (40 bytes)
    class SHA1 < Transform
      delegate_to ::Digest::SHA1, %i[hexdigest]
    end
  end
end
