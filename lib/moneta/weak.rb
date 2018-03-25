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

  # Adds weak key enumeration support to the underlying store
  #
  # @note The each_key method hooks into the methods that stores or access the values to collect or discover which keys are valid
  # so by no means it "knows" the state of the data (this is meant by weak).
  # @api public
  class WeakEachKey < Proxy
    include EachKeySupport

    # @param [Moneta store] adapter The underlying store
    # @param [Hash] options
    def initialize(adapter, options = {})
      raise 'Store already supports feature :each_key' if adapter.supports?(:each_key)
      super
    end
  end
end
