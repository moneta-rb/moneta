module Juno
  # Adds expiration support to the underlying store
  #
  # #store and #load support the :expires options to set/update
  # the expiration time.
  #
  # @api public
  class Expires < Proxy
    def key?(key, options = {})
      !!load(key, options)
    end

    def load(key, options = {})
      value = check_expired(key, super(key, options))
      if value && options.include?(:expires)
        store(key, value, options)
      else
        value
      end
    end

    def store(key, value, options = {})
      if expires = options.delete(:expires)
        super(key, [value, Time.now.to_i + expires].compact, options)
      else
        super(key, [value], options)
      end
      value
    end

    def delete(key, options = {})
      check_expired(key, super, false)
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
