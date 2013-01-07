module Moneta
  module Weak
    class Create < Proxy
      include CreateSupport
    end

    class Increment < Proxy
      include IncrementSupport
    end
  end
end
