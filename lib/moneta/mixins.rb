module Moneta
  # @api private
  module WithOptions
    def with(options)
      OptionMerger.new(self, options)
    end

    def raw
      @raw_store ||=
        begin
          store = with(:raw => true, :only => [:load, :store, :delete])
          store.instance_variable_set(:@raw_store, store)
          store
        end
    end

    def prefix(prefix)
      with(:prefix => prefix, :except => :clear)
    end

    def expires(expires)
      with(:expires => expires, :only => [:store, :increment])
    end
  end

  # Simple interface to key/value stores with Hash-like interface.
  # @api public
  module Defaults
    include WithOptions

    # Exists the value with key
    #
    # @param [Object] key
    # @return [Boolean]
    # @param [Hash] options
    # @api public
    def key?(key, options = {})
      load(key, options) != nil
    end

    # Atomically increment integer value with key
    #
    # Not every Moneta store implements this method,
    # a NotImplementedError if it is not supported.
    #
    # This method also accepts negative amounts.
    #
    # @param [Object] key
    # @param [Integer] amount
    # @param [Hash] options
    # @return [Object] value from store
    # @api public
    def increment(key, amount = 1, options = {})
      raise NotImplementedError, 'increment is not supported'
    end

    # Atomically decrement integer value with key
    #
    # This is just syntactic sugar for calling #increment with a negative value.
    #
    # This method also accepts negative amounts.
    #
    # @param [Object] key
    # @param [Integer] amount
    # @param [Hash] options
    # @return [Object] value from store
    # @api public
    def decrement(key, amount = 1, options = {})
      increment(key, -amount, options)
    end

    # Explicitly close the store
    # @return nil
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
        result = load(key, default || {})
        result == nil ? yield(key) : result
      else
        result = load(key, options || {})
        result == nil ? default : result
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

  # @api private
  module IncrementSupport
    def increment(key, amount = 1, options = {})
      value = load(key, options)
      intvalue = value.to_i
      raise 'Tried to increment non integer value' unless value == nil || intvalue.to_s == value.to_s
      intvalue += amount
      store(key, intvalue.to_s, options)
      intvalue
    end
  end

  # @api private
  module HashAdapter
    def key?(key, options = {})
      @hash.has_key?(key)
    end

    def load(key, options = {})
      @hash[key]
    end

    def store(key, value, options = {})
      @hash[key] = value
    end

    def delete(key, options = {})
      @hash.delete(key)
    end

    def clear(options = {})
      @hash.clear
      self
    end
  end

  # @api private
  module Net
    DEFAULT_PORT = 9000

    class Error < RuntimeError; end

    def pack(o)
      s = Marshal.dump(o)
      [s.bytesize].pack('N') << s
    end

    def read(io)
      size = io.read(4).unpack('N').first
      Marshal.load(io.read(size))
    end

    def write(io, o)
      io.write(pack(o))
    end
  end
end
