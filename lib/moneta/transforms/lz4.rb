require 'lz4-ruby'

module Moneta
  module Transforms
    class LZ4 < Transform
      delegate_to ::LZ4, %i[compress uncompress]
    end
  end
end
