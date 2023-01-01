require 'digest/rmd160'

module Moneta
  module Transforms
    class RMD160 < Transform
      delegate_to ::Digest::RMD160, %i[hexdigest]
    end
  end
end
