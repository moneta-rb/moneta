module Moneta
  module Transforms
    class Marshal < Transform::Serializer
      delegate_to ::Marshal
    end
  end
end
