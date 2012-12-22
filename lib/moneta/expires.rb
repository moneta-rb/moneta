module Moneta
  # Adds expiration support to the underlying store
  #
  # #store and #load support the :expires option to set/update
  # the expiration time.
  #
  # @api public
  class Expires < Proxy
    # Constructor
    #
    # @param [Moneta store] adapter The underlying store
    # @param [Hash] options
    #
    # Options:
    # * :expires - Default expiration time (default none)
    def initialize(adapter, options = {})
      super
      @expires = options[:expires]
    end

    def key?(key, options = {})
      load(key, options) != nil
    end

    def load(key, options = {})
      if options.include?(:raw)
        super
      else
        value = check_expired(key, super)
        if value && options.include?(:expires)
          store(key, value, options)
        else
          value
        end
      end
    end

    def store(key, value, options = {})
      if options.include?(:raw)
        super
      else
        if expires = (options.delete(:expires) || @expires)
          super(key, [value, Time.now.to_i + expires], options)
        else
          super(key, [value], options)
        end
        value
      end
    end

    def delete(key, options = {})
      if options.include?(:raw)
        super
      else
        check_expired(key, super, false)
      end
    end

    protected

    def check_expired(key, value, delete_expired = true)
      value, expires = value
      if expires && Time.now.to_i > expires
        delete(key) if delete_expired
        nil
      else
        value
      end
    end
  end
end
