require 'digest/sha2'

module Moneta
  module Transforms
    class SHA384 < Transform
      delegate_to ::Digest::SHA384, %i[hexdigest]
    end
  end
end
