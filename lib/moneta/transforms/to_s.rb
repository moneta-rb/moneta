module Moneta
  module Transforms
    class ToS < Transform
      encode { |value| value.to_s }
    end
  end
end
