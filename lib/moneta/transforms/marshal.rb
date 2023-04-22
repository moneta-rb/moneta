module Moneta
  module Transforms
    # Serializes objects to strings using +Marshal+
    class Marshal < Transform::Serializer
      delegate_to ::Marshal
    end
  end
end
