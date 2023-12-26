require "lzma"

module Moneta
  module Transforms
    # Compresses strings using the {https://rubygems.org/gems/ruby-lzma ruby-lzma gem}
    class LZMA < Transform
      delegate_to ::LZMA, %i[compress decompress]
    end
  end
end
