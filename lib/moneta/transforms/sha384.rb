require "digest/sha2"

module Moneta
  module Transforms
    # Hashes strings using SHA-384, encoded as a hex string (96 bytes)
    class SHA384 < Transform
      delegate_to ::Digest::SHA384, %i[hexdigest]
    end
  end
end
