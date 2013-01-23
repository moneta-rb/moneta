module Moneta
  # Adds weak create support to the underlying store
  #
  # @note The increment method will not be thread or multi-process safe (this is meant by weak)
  # @api public
  class WeakCreate < Proxy
    include CreateSupport
  end

  # Adds weak increment support to the underlying store
  #
  # @note The increment method will not be thread or multi-process safe (this is meant by weak)
  # @api public
  class WeakIncrement < Proxy
    include IncrementSupport
  end
end
