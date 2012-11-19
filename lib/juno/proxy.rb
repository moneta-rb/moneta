module Juno
  class Proxy < Base
    def initialize(store)
      @store = store
    end

    # Exists the value with key
    #
    # @param [Object] key
    # @return [Boolean]
    # @param [Hash] options
    # @api public
    def key?(key, options = {})
      @store.key?(key, options)
    end

    # Fetch value with key. Return nil if the key doesn't exist
    #
    # @param [Object] key
    # @param [Hash] options
    # @return [Object] value
    # @api public
    def load(key, options = {})
      @store.load(key, options)
    end

    # Store value with key
    #
    # @param [Object] key
    # @param [Object] value
    # @param [Hash] options
    # @return value
    # @api public
    def store(key, value, options = {})
      @store.store(key, value, options)
    end

    # Delete the key from the store and return the current value
    #
    # @param [Object] key
    # @return [Object] current value
    # @param [Hash] options
    # @api public
    def delete(key, options = {})
      @store.delete(key, options)
    end

    # Clear all keys in this store
    #
    # @param [Hash] options
    # @return [void]
    # @api public
    def clear(options = {})
      @store.clear(options)
    end

    def close
      @store.close
    end
  end
end
