module Juno
  # Simple interface to key/value stores with Hash-like interface.
  # @api public
  class Base
    # Exists the value with key
    #
    # @param [Object] key
    # @return [Boolean]
    # @param [Hash] options
    # @api public
    def key?(key, options = {})
      !!load(key, options)
    end

    # Explicitly close the store
    # @api public
    def close
    end

    # Fetch value with key
    #
    # This is a overloaded method:
    #
    # * fetch(key, options = {}, &block) retrieve a key. if the key is not available, execute the
    #   block and return its return value.
    #
    # * fetch(key, value, options = {}) retrieve a key. if the key is not available, return the value.
    #
    # @param [Object] key
    # @param [Object] default Default value
    # @param [Hash] options
    # @return [Object] value from store
    # @api public
    def fetch(key, default = nil, options = nil)
      if block_given?
        raise ArgumentError, 'Only one argument accepted if block is given' if options
        load(key, default || {}) || yield(key)
      else
        load(key, options || {}) || default
      end
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
