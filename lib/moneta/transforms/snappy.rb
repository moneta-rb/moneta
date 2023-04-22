require "snappy"

module Moneta
  module Transforms
    # Compresses strings using the {https://rubygems.org/gems/snappy snappy gem}.
    #
    # @see https://github.com/google/snappy#readme
    class Snappy < Transform
      delegate_to ::Snappy, %i[deflate inflate]
    end
  end
end
