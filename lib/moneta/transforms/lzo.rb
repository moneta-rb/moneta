require 'lzoruby'

module Moneta
  module Transforms
    class LZO < Transform
      delegate_to ::LZO, %i[compress decompress]
    end
  end
end
