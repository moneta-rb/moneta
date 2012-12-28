module Moneta
  # @api private
  module OptionSupport
    # Return Moneta store with default options
    #
    # @param [Hash] options Options to merge
    # @return [OptionMerger]
    # @api public
    def with(options)
      OptionMerger.new(self, options)
    end

    # Return Moneta store with default option :raw => true
    #
    # @return [OptionMerger]
    # @api public
    def raw
      @raw_store ||=
        begin
          store = with(:raw => true, :only => [:load, :store, :delete])
          store.instance_variable_set(:@raw_store, store)
          store
        end
    end

    # Return Moneta store with default prefix option
    #
    # @param [String] prefix Key prefix
    # @return [OptionMerger]
    # @api public
    def prefix(prefix)
      with(:prefix => prefix, :except => :clear)
    end

    # Return Moneta store with default expiration time
    #
    # @param [Integer] expires Default expiration time
    # @return [OptionMerger]
    # @api public
    def expires(expires)
      with(:expires => expires, :only => [:store, :increment])
    end
  end

  # Simple interface to key/value stores with Hash-like interface.
  # @api public
  module Defaults
    include OptionSupport

    # Exists the value with key
    #
    # @param [Object] key
    # @param [Hash] options
    # @return [Boolean]
    # @api public
    def key?(key, options = {})
      load(key, options) != nil
    end

    # Atomically increment integer value with key
    #
    # This method also accepts negative amounts.
    #
    # @note Not every Moneta store implements this method,
    #       a NotImplementedError is raised if it is not supported.
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

    # Fetch a value with a key
    #
    # @overload fetch(key, options = {}, &block)
    #   retrieve a key. if the key is not available, execute the
    #   block and return its return value.
    #   @param [Object] key
    #   @param [Hash] options
    #   @return [Object] value from store
    #
    # @overload fetch(key, default, options = {})
    #   retrieve a key. if the key is not available, return the default value.
    #   @param [Object] key
    #   @param [Object] default Default value
    #   @param [Hash] options
    #   @return [Object] value from store
    #
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
    # (see Defaults#increment)
    # @api public
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
    # (see Proxy#key?)
    def key?(key, options = {})
      @hash.has_key?(key)
    end

    # (see Proxy#load)
    def load(key, options = {})
      @hash[key]
    end

    # (see Proxy#store)
    def store(key, value, options = {})
      @hash[key] = value
    end

    # (see Proxy#delete)
    def delete(key, options = {})
      @hash.delete(key)
    end

    # (see Proxy#clear)
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
