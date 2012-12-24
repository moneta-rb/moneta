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
      load_entry(key, options) != nil
    end

    def load(key, options = {})
      return super if options.include?(:raw)
      value, expires = load_entry(key, options)
      value
    end

    def store(key, value, options = {})
      return super if options.include?(:raw)
      if expires = (options.delete(:expires) || @expires)
        super(key, [value, Time.now.to_i + expires], options)
      else
        super(key, [value], options)
      end
      value
    end

    def delete(key, options = {})
      return super if options.include?(:raw)
      value, expires = super
      value if !expires || Time.now.to_i <= expires
    end

    private

    def load_entry(key, options)
      new_expires = options.delete(:expires)
      if entry = @adapter.load(key, options)
        value, expires = entry
        if expires && Time.now.to_i > expires
          delete(key)
          nil
        elsif new_expires
          @adapter.store(key, [value, Time.now.to_i + new_expires], options)
          entry
        else
          entry
        end
      end
    end
  end
end
