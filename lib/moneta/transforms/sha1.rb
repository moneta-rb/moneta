require 'digest/sha1'

module Moneta
  module Transforms
    class SHA1 < Transform
      delegate_to ::Digest::SHA1, %i[hexdigest]
    end
  end
end
