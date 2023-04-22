require "ox"

module Moneta
  module Transforms
    # Serializes objects to XML using the {https://rubygems.org/gems/ox ox gem}.  See
    # {https://github.com/ohler55/ox#object-xml-format} for details of the format.
    class Ox < Transform::Serializer
      delegate_to ::Ox, %i[dump parse_obj]
    end
  end
end
