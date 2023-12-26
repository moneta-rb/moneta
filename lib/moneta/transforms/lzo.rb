require "lzoruby"

module Moneta
  module Transforms
    # Compresses strings using the {https://rubygems.org/gems/lzoruby lzoruby gem}
    class LZO < Transform
      delegate_to ::LZO, %i[compress decompress]
    end
  end
end
