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
    # @option options [Integer] :expires Update expiration time (See `Moneta::Expires`)
    # @option options [String] :prefix Prefix key (See `Moneta::Transformer`)
    # @option options Other options as defined by the adapters or middleware
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
      value = convert_for_increment(load(key, options)) + amount
      store(key, value.to_s, options)
      value
    end

    protected

    def convert_for_increment(value)
      intvalue = value.to_i
      raise 'Tried to increment non integer value' unless value == nil || intvalue.to_s == value.to_s
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

  # This mixin handles the calculation of expiration times.
  #
  #
  module DefaultExpires

    attr_reader :default_expires

    # Checks whether a default expiration is set.
    def default_expires?
      return default_expires.kind_of?(Numeric) && default_expires >= 0
    end

  protected

    attr_writer :default_expires

    # Calculates the time when something will expire.
    #
    # @param [true,false,nil,Numeric] value a value given by user
    # @param [Boolean] use_default take the default value if value is nil
    #
    # @return [false] if it should not expire
    # @return [Time] the time when something should expire
    # @return [nil] if it is not known
    def expiration_time(value, use_default = true)
      value = expiration_value(value, use_default)
      return value unless value.kind_of? Numeric
      return Time.now + value
    end

    # Calculates the number of seconds something should last (ttl).
    #
    # @param [true,false,nil,Numeric] value a value given by user
    # @param [Boolean] use_default take the default value if value is nil
    #
    # @return [false] if it should not expire
    # @return [Numeric] seconds until expiration
    # @return [nil] if it is not known
    def expiration_value(value, use_default = true)
      return false if value == false
      if ( value.nil? && use_default ) || value == true
        if default_expires?
          return default_expires.to_i
        else
          return false
        end
      elsif value.nil?
        return nil
      end
      result = value.to_i
      if result <= 0
        raise ArgumentError, "Expected a value bigger than 0 as expiration, but got #{result.inspect}."
      end
      return result
    end

    alias ttl expiration_value

    def expiration_time_without_default(value)
      expiration_time(value, false)
    end

    def expiration_value_without_default(value)
      expiration_value(value, false)
    end

  end
end
