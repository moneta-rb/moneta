require 'digest/sha2'

module Moneta
  module Transforms
    class SHA256 < Transform
      delegate_to ::Digest::SHA256, %i[hexdigest]
    end
  end
end
