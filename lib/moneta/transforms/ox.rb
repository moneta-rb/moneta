require 'ox'

module Moneta
  module Transforms
    class Ox < Transform::Serializer
      delegate_to ::Ox, %i[parse_obj dump]
    end
  end
end
