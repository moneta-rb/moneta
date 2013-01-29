module Moneta
  # Adds weak create support to the underlying store
  #
  # @note The create method will not be thread or multi-process safe (this is meant by weak)
  # @api public
  class WeakCreate < Proxy
    include CreateSupport

    # @param [Moneta store] adapter The underlying store
    # @param [Hash] options
    def initialize(adapter, options = {})
      raise 'Store already supports feature :create' if adapter.supports?(:create)
      super
    end
  end

  # Adds weak increment support to the underlying store
  #
  # @note The increment method will not be thread or multi-process safe (this is meant by weak)
  # @api public
  class WeakIncrement < Proxy
    include IncrementSupport

    # @param [Moneta store] adapter The underlying store
    # @param [Hash] options
    def initialize(adapter, options = {})
      raise 'Store already supports feature :increment' if adapter.supports?(:increment)
      super
    end
  end
end
