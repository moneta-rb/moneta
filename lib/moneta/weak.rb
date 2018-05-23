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
  # @note This class wraps methods that store and retrieve entries in order to
  #   track which keys are in the store, and uses this list when doing key
  #   traversal.  This means that {#each_key each_key} will only yield keys
  #   which have been accessed previously via the present store object.  This
  #   wrapper is therefore best suited to adapters which are not persistent, and
  #   which cannot be shared (e.g. {Adapters::LRUHash LRUHash}).
  #
  # @api public
  class WeakEachKey < Proxy
    prepend EachKeySupport

    # @param [Moneta store] adapter The underlying store
    # @param [Hash] options
    def initialize(adapter, options = {})
      raise 'Store already supports feature :each_key' if adapter.supports?(:each_key)
      super
    end
  end
end
