module Moneta
  class WeakCreate < Proxy
    include CreateSupport
  end

  class WeakIncrement < Proxy
    include IncrementSupport
  end
end
