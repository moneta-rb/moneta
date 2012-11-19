module Juno
  # Simple interface to key/value stores with Hash-like interface.
  #
  # @abstract
  class Base
    # Exists the value with key
    #
    # @param [Object] key
    # @return [Boolean]
    # @param [Hash] options
    # @api public
    def key?(key, options = {})
      @store.has_key?(key_for(key))
    end

    def has_key?(key, options = {})
      key?(key, options)
    end

    # Fetch value with key. Return nil if the key doesn't exist
    #
    # @param [Object] key
    # @return [Object] value
    # @api public
    def [](key)
      deserialize(@store[key_for(key)])
    end

    # Store value with key
    #
    # @param [Object] key
    # @param [Object] value
    # @param [Hash] options
    # @return value
    # @api public
    def store(key, value, options = {})
      @store[key_for(key)] = serialize(value)
      value
    end

    # Delete the key from the store and return the current value
    #
    # @param [Object] key
    # @return [Object] current value
    # @param [Hash] options
    # @api public
    def delete(key, options = {})
      deserialize(@store.delete(key_for(key)))
    end

    # Clear all keys in this store
    #
    # @param [Hash] options
    # @return [void]
    # @api public
    def clear(options = {})
      @store.clear
      nil
    end

    # Fetch value with key. Return default if value is nil.
    #
    # @param [Object] key
    # @param [Object] value Default value
    # @param [Hash] options
    # @return [Object] value from store
    # @api public
    def fetch(key, value = nil, options = {})
      self[key] || (block_given? && yield(key)) || value
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

    # Explicitly close the store
    # @api public
    def close
      nil
    end

    protected

    # Serialize value
    #
    # @param [Object] value Serializable object
    # @return [String] serialized object
    # @api private
    def serialize(value)
      Marshal.dump(value)
    end

    # Deserialize value
    #
    # @param [String] value Serialized object
    # @return [Object] Deserialized object
    # @api private
    def deserialize(value)
      value && Marshal.load(value)
    end

    # Convert key to string
    #
    # @param [Object] key Key
    # @return [String] Marshalled key
    # @api private
    def key_for(key)
      String === key ? key : Marshal.dump(key)
    end
  end
end
