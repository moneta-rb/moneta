require 'lzma'

module Moneta
  module Transforms
    class LZMA < Transform
      delegate_to ::LZMA, %i[compress decompress]
    end
  end
end
