require "lz4-ruby"

module Moneta
  module Transforms
    # Compresses strings using the {https://rubygems.org/gems/lz4-ruby lz4-ruby gem}
    class LZ4 < Transform
      delegate_to ::LZ4, %i[compress uncompress]
    end
  end
end
