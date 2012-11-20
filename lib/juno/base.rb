module Juno
  # Simple interface to key/value stores with Hash-like interface.
  class Base
    # Explicitly close the store
    # @api public
    def close
    end

    # Fetch value with key. Return default if value is nil.
    #
    # @param [Object] key
    # @param [Object] value Default value
    # @param [Hash] options
    # @return [Object] value from store
    # @api public
    def fetch(key, value = nil, options = {})
      load(key, options) || (block_given? && yield(key)) || value
    end

    # Fetch value with key. Return nil if the key doesn't exist
    #
    # @param [Object] key
    # @return [Object] value
    # @api public
    def [](key)
      load(key)
    end

    # Store value with key
    #
    # @param [Object] key
    # @param [Object] value
    # @return value
    # @api public
    def []=(key, value)
      store(key, value)
    end
  end
end
