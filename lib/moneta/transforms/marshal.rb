module Moneta
  module Transforms
    class Marshal < Transform
      delegate_to ::Marshal
    end
  end
end
