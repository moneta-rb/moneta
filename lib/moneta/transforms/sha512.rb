require "digest/sha2"

module Moneta
  module Transforms
    class SHA512 < Transform
      delegate_to ::Digest::SHA512, %i[hexdigest]
    end
  end
end
