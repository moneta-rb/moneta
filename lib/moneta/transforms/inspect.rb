module Moneta
  module Transforms
    class Inspect < Transform
      encode { |value| value.inspect }
    end
  end
end
