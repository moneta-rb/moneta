require 'snappy'

module Moneta
  module Transforms
    class Snappy < Transform
      delegate_to ::Snappy, %i[deflate inflate]
    end
  end
end
